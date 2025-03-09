const port = process.env.PORT || 3000;
const cors = require('cors');

// Update CORS configuration
app.use(cors({
    origin: [
        'https://your-frontend-domain.com',  // Replace with your actual frontend domain
        'http://localhost:3000',             // For local development
        'http://localhost:5173'              // If using Vite default port
    ],
    credentials: true
}));

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
}); 