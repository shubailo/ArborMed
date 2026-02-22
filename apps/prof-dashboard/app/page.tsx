export default function Page() {
    return (
        <main style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            height: '100vh',
            fontFamily: 'system-ui, sans-serif'
        }}>
            <h1>ArborMed Professor Dashboard</h1>
            <p>Status: 🏗️ Under Construction (Building Infrastructure)</p>
            <div style={{ marginTop: '20px', padding: '10px', border: '1px solid #ccc', borderRadius: '8px' }}>
                <p>CI/CD Verification: ✅ Deployment Successful</p>
            </div>
        </main>
    );
}
