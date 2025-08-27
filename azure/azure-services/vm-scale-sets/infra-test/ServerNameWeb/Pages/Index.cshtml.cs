using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Net.Http;

namespace ServerNameWeb.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    [BindProperty]
    public string? Fqdn { get; set; }
    public string? ServerName { get; private set; }


    public IndexModel(ILogger<IndexModel> logger, IHttpClientFactory httpClientFactory)
    {
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public async Task OnGetAsync()
    {
        // No API call on GET
    }

    public async Task<IActionResult> OnPostAsync()
    {
       // ...existing code...
        if (!string.IsNullOrWhiteSpace(Fqdn))
        {
            // Create a new HttpClientHandler and HttpClient for each request
            using var handler = new HttpClientHandler();
            using var client = new HttpClient(handler);

            try
            {
                var url = $"http://{Fqdn}/servername";
                ServerName = await client.GetStringAsync(url);
            }
            catch (Exception ex)
            {
                ServerName = $"Error: {ex.Message}";
            }
        }
        // ...existing code...
        return Page();
    }

}
