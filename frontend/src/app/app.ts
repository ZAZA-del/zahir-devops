import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-root',
  standalone: true,
  template: `
    <div class="container">
      <header>
        <h1>Zahir DevOps</h1>
        <p class="subtitle">Cloud-native deployment on AWS EKS</p>
      </header>
      <div class="cards">
        <div class="card">
          <h2>Backend Response</h2>
          <div class="response">
            @if (loading) {
              <span>Connecting to API...</span>
            } @else if (error) {
              <span class="err">{{ error }}</span>
            } @else {
              <span class="message">{{ message }}</span>
            }
          </div>
          <div class="endpoint">GET /api/hello</div>
        </div>
        <div class="card">
          <h2>Stack</h2>
          <table>
            <tr><td>Backend</td><td>Java Spring Boot 3.5</td></tr>
            <tr><td>Frontend</td><td>Angular 21</td></tr>
            <tr><td>Compute</td><td>AWS EKS (Kubernetes)</td></tr>
            <tr><td>Logging</td><td>Elasticsearch + Kibana</td></tr>
            <tr><td>CI/CD</td><td>GitHub Actions</td></tr>
          </table>
        </div>
      </div>
    </div>
  `,
  styles: [`
    * { box-sizing: border-box; margin: 0; padding: 0; }
    :host { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
    .container { background: #0f172a; min-height: 100vh; padding: 40px 20px; color: #e2e8f0; max-width: 900px; margin: 0 auto; }
    header { text-align: center; margin-bottom: 40px; }
    h1 { font-size: 2.5rem; font-weight: 700; background: linear-gradient(135deg, #667eea, #764ba2); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .subtitle { color: #94a3b8; margin-top: 8px; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; }
    .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 24px; }
    h2 { color: #94a3b8; font-size: 0.875rem; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 16px; }
    .response { background: #0f172a; border-radius: 8px; padding: 20px; text-align: center; min-height: 60px; display: flex; align-items: center; justify-content: center; }
    .message { font-size: 1.5rem; font-weight: 600; color: #34d399; }
    .err { color: #f87171; font-size: 0.875rem; }
    .endpoint { margin-top: 12px; font-size: 0.75rem; color: #475569; font-family: monospace; }
    table { width: 100%; border-collapse: collapse; }
    td { padding: 8px 0; border-bottom: 1px solid #334155; font-size: 0.875rem; }
    td:first-child { color: #94a3b8; }
    td:last-child { color: #e2e8f0; text-align: right; }
  `]
})
export class AppComponent implements OnInit {
  message = '';
  error = '';
  loading = true;

  constructor(private http: HttpClient) {}

  ngOnInit() {
    this.http.get('/api/hello', { responseType: 'text' }).subscribe({
      next: (resp) => { this.message = resp; this.loading = false; },
      error: () => { this.error = 'Backend unreachable'; this.loading = false; }
    });
  }
}
