using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Net.Http.Headers;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var contentTypeProvider = new FileExtensionContentTypeProvider();
contentTypeProvider.Mappings[".br"] = "application/octect-stream";
builder.Services.Configure<StaticFileOptions>(options =>
{
    options.ContentTypeProvider = contentTypeProvider;
    options.OnPrepareResponse = fileContext =>
    {
        var loggerFactory = fileContext.Context.RequestServices.GetRequiredService<ILoggerFactory>();
        var logger = loggerFactory.CreateLogger("StaticFiles");

        // At this point we mapped something from the /_framework
        fileContext.Context.Response.Headers.Append(HeaderNames.CacheControl, "no-cache");

        var requestPath = fileContext.Context.Request.Path;
        var fileExtension = Path.GetExtension(requestPath.Value);
        logger.LogInformation("File extension for {Path} is {Extension}", requestPath.Value, fileExtension);
        if (string.Equals(fileExtension, ".gz") || string.Equals(fileExtension, ".br"))
        {
            logger.LogInformation("Serving pre-compressed file for {Path}", requestPath.Value);
            // When we are serving framework files (under _framework/ we perform content negotiation
            // on the accept encoding and replace the path with <<original>>.gz|br if we can serve gzip or brotli content
            // respectively.
            // Here we simply calculate the original content type by removing the extension and apply it
            // again.
            // When we revisit this, we should consider calculating the original content type and storing it
            // in the request along with the original target path so that we don't have to calculate it here.
            var originalPath = Path.GetFileNameWithoutExtension(requestPath.Value);
            if (originalPath != null && contentTypeProvider.TryGetContentType(originalPath, out var originalContentType))
            {
                logger.LogInformation("Original content type for {Path} is {ContentType}", originalPath, originalContentType);
                fileContext.Context.Response.ContentType = originalContentType;
            }
        }
    };
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.Use((ctx, nxt) =>
{
    var loggerFactory = ctx.RequestServices.GetRequiredService<ILoggerFactory>();
    var logger = loggerFactory.CreateLogger("Compression");
    var path = ctx.Request.Path;
    if (path == "/")
    {
        logger.LogInformation("Using index.html for {Path}", path);
        path = "/index.html";
    }
    logger.LogInformation("Checking for compressed file for {Path}", path);
    var originalExtension = Path.GetExtension(path);
    if (!string.IsNullOrEmpty(originalExtension))
    {
        logger.LogInformation("Compressing {Path}", path);
        var webHostEnvironment = ctx.RequestServices.GetRequiredService<IWebHostEnvironment>();
        var fileProvider = webHostEnvironment.WebRootFileProvider;
        var br = fileProvider.GetFileInfo(path + ".br");
        var gz = fileProvider.GetFileInfo(path + ".gz");
        if (br != null && br.Exists)
        {
            logger.LogInformation("Using Brotli compressed file {Path}.br", path);
            ctx.Request.Path = path + ".br";
            ctx.Response.Headers.ContentEncoding = "br";
            logger.LogInformation("Content type {ContentType}", ctx.Response.ContentType);
        }
        else if (gz != null && gz.Exists)
        {
            logger.LogInformation("Using GZip compressed file {Path}.gz", path);
            ctx.Request.Path = path + ".gz";
            ctx.Response.Headers.ContentEncoding = "gzip";
            logger.LogInformation("Content type {ContentType}", ctx.Response.ContentType);
        }
    }

    return nxt();
});

app.UseStaticFiles();

app.UseAuthorization();

app.MapControllers();

app.Run();