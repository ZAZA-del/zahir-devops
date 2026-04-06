import React, { useState, useEffect } from 'react';

const API_URL = import.meta.env.VITE_API_URL || '';

const styles = {
  container: {
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    maxWidth: '900px',
    margin: '0 auto',
    padding: '40px 20px',
    background: '#0f172a',
    minHeight: '100vh',
    color: '#e2e8f0'
  },
  header: {
    textAlign: 'center',
    marginBottom: '40px'
  },
  title: {
    fontSize: '2.5rem',
    fontWeight: 700,
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
    marginBottom: '8px'
  },
  subtitle: { color: '#94a3b8', fontSize: '1rem' },
  grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px' },
  card: {
    background: '#1e293b',
    borderRadius: '12px',
    padding: '24px',
    border: '1px solid #334155'
  },
  cardTitle: { fontSize: '1rem', fontWeight: 600, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '16px' },
  statusBadge: (ok) => ({
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    padding: '4px 12px',
    borderRadius: '20px',
    fontSize: '0.875rem',
    fontWeight: 500,
    background: ok ? '#064e3b' : '#7f1d1d',
    color: ok ? '#34d399' : '#f87171'
  }),
  dot: (ok) => ({
    width: '8px', height: '8px', borderRadius: '50%',
    background: ok ? '#34d399' : '#f87171',
    animation: ok ? 'pulse 2s infinite' : 'none'
  }),
  stackItem: { display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #334155' },
  label: { color: '#94a3b8', fontSize: '0.875rem' },
  value: { color: '#e2e8f0', fontSize: '0.875rem', fontWeight: 500 },
  error: { color: '#f87171', fontSize: '0.875rem', marginTop: '8px' }
};

export default function App() {
  const [health, setHealth] = useState(null);
  const [info, setInfo] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [healthRes, infoRes] = await Promise.all([
          fetch(`${API_URL}/health`),
          fetch(`${API_URL}/api/info`)
        ]);
        setHealth(await healthRes.json());
        setInfo(await infoRes.json());
      } catch (e) {
        setError(e.message);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const isHealthy = health?.status === 'healthy';

  return (
    <>
      <style>{`
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: #0f172a; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
      `}</style>
      <div style={styles.container}>
        <div style={styles.header}>
          <h1 style={styles.title}>Zahir DevOps</h1>
          <p style={styles.subtitle}>Production-ready cloud infrastructure dashboard</p>
        </div>

        {loading ? (
          <p style={{ textAlign: 'center', color: '#94a3b8' }}>Connecting to API...</p>
        ) : (
          <div style={styles.grid}>
            <div style={styles.card}>
              <div style={styles.cardTitle}>API Health</div>
              <div style={styles.statusBadge(isHealthy)}>
                <div style={styles.dot(isHealthy)} />
                {isHealthy ? 'Healthy' : 'Unhealthy'}
              </div>
              {health && (
                <div style={{ marginTop: '16px' }}>
                  <div style={styles.stackItem}>
                    <span style={styles.label}>Version</span>
                    <span style={styles.value}>{health.version}</span>
                  </div>
                  <div style={styles.stackItem}>
                    <span style={styles.label}>Environment</span>
                    <span style={styles.value}>{health.environment}</span>
                  </div>
                  <div style={{ ...styles.stackItem, borderBottom: 'none' }}>
                    <span style={styles.label}>Timestamp</span>
                    <span style={styles.value}>{new Date(health.timestamp).toLocaleTimeString()}</span>
                  </div>
                </div>
              )}
              {error && <p style={styles.error}>Error: {error}</p>}
            </div>

            {info && (
              <div style={styles.card}>
                <div style={styles.cardTitle}>Tech Stack</div>
                {Object.entries(info.stack).map(([k, v]) => (
                  <div key={k} style={styles.stackItem}>
                    <span style={styles.label}>{k.replace(/_/g, ' ')}</span>
                    <span style={styles.value}>{v}</span>
                  </div>
                ))}
              </div>
            )}

            {info && (
              <div style={styles.card}>
                <div style={styles.cardTitle}>System Info</div>
                <div style={styles.stackItem}>
                  <span style={styles.label}>Uptime</span>
                  <span style={styles.value}>{Math.floor(info.uptime)}s</span>
                </div>
                <div style={styles.stackItem}>
                  <span style={styles.label}>Heap Used</span>
                  <span style={styles.value}>{Math.round(info.memory?.heapUsed / 1024 / 1024)}MB</span>
                </div>
                <div style={{ ...styles.stackItem, borderBottom: 'none' }}>
                  <span style={styles.label}>Project</span>
                  <span style={styles.value}>{info.project}</span>
                </div>
              </div>
            )}

            <div style={styles.card}>
              <div style={styles.cardTitle}>Infrastructure</div>
              {[
                ['Cloud', 'AWS'],
                ['Compute', 'ECS Fargate'],
                ['Registry', 'ECR'],
                ['Load Balancer', 'ALB'],
                ['Logging', 'OpenSearch'],
                ['CI/CD', 'GitHub Actions']
              ].map(([k, v]) => (
                <div key={k} style={styles.stackItem}>
                  <span style={styles.label}>{k}</span>
                  <span style={styles.value}>{v}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </>
  );
}
