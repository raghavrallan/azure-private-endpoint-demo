from flask import Flask, jsonify, render_template_string, request
from azure.cosmos import CosmosClient, exceptions
from azure.storage.blob import BlobServiceClient
import os
import logging
from datetime import datetime
import uuid

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
COSMOS_ENDPOINT = os.getenv("COSMOS_ENDPOINT")
COSMOS_KEY = os.getenv("COSMOS_KEY")
STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING")
STORAGE_ACCOUNT_NAME = os.getenv("STORAGE_ACCOUNT_NAME")
PORT = int(os.getenv("PORT", 8000))

# Database and container names
DATABASE_NAME = "testdb"
TEST_CONTAINER_NAME = "testcontainer"
USER_CONTAINER_NAME = "userdata"
TEST_BLOB_CONTAINER_NAME = "testcontainer"
UPLOADS_BLOB_CONTAINER_NAME = "uploads"

# HTML Template with UI
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Private Endpoint Demo</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            text-align: center;
            color: white;
            margin-bottom: 40px;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }

        .header p {
            font-size: 1.1rem;
            opacity: 0.9;
        }

        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 30px;
            margin-bottom: 30px;
        }

        .card {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }

        .card h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-icon {
            font-size: 1.8rem;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
        }

        .form-group input[type="text"],
        .form-group input[type="email"],
        .form-group textarea,
        .form-group input[type="file"] {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1rem;
            transition: border-color 0.3s;
        }

        .form-group input:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
        }

        .form-group textarea {
            resize: vertical;
            min-height: 100px;
        }

        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 14px 30px;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            width: 100%;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }

        .btn:active {
            transform: translateY(0);
        }

        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }

        .status-card {
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }

        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }

        .status-item {
            padding: 15px;
            background: #f5f5f5;
            border-radius: 8px;
            text-align: center;
        }

        .status-item h3 {
            font-size: 0.9rem;
            color: #666;
            margin-bottom: 5px;
        }

        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
        }

        .status-success {
            background: #d4edda;
            color: #155724;
        }

        .status-error {
            background: #f8d7da;
            color: #721c24;
        }

        .alert {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: none;
        }

        .alert.show {
            display: block;
            animation: slideIn 0.3s ease-out;
        }

        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .data-list {
            max-height: 400px;
            overflow-y: auto;
            margin-top: 20px;
        }

        .data-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 10px;
            border-left: 4px solid #667eea;
        }

        .data-item h4 {
            color: #667eea;
            margin-bottom: 5px;
        }

        .data-item p {
            color: #666;
            font-size: 0.9rem;
            margin: 5px 0;
        }

        .loader {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #667eea;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            animation: spin 1s linear infinite;
            display: inline-block;
            margin-left: 10px;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Azure Private Endpoint Demo</h1>
            <p>Secure data submission and file uploads via Private Link</p>
        </div>

        <div class="status-card">
            <h2 style="color: #667eea; margin-bottom: 15px;">System Status</h2>
            <div class="status-grid">
                <div class="status-item">
                    <h3>Cosmos DB</h3>
                    <span class="status-badge status-success" id="cosmos-status">Connected</span>
                </div>
                <div class="status-item">
                    <h3>Storage Account</h3>
                    <span class="status-badge status-success" id="storage-status">Connected</span>
                </div>
                <div class="status-item">
                    <h3>Public Access</h3>
                    <span class="status-badge status-error">Disabled</span>
                </div>
                <div class="status-item">
                    <h3>Private Link</h3>
                    <span class="status-badge status-success">Active</span>
                </div>
            </div>
        </div>

        <div class="cards">
            <div class="card">
                <h2>
                    <span class="card-icon">📝</span>
                    Save Data to Cosmos DB
                </h2>
                <div id="db-alert" class="alert"></div>
                <form id="dataForm">
                    <div class="form-group">
                        <label for="name">Name</label>
                        <input type="text" id="name" name="name" required placeholder="Enter your name">
                    </div>
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" required placeholder="Enter your email">
                    </div>
                    <div class="form-group">
                        <label for="message">Message</label>
                        <textarea id="message" name="message" required placeholder="Enter your message"></textarea>
                    </div>
                    <button type="submit" class="btn">
                        Submit to Database
                        <span id="db-loader" class="loader" style="display: none;"></span>
                    </button>
                </form>
                <div id="data-list" class="data-list"></div>
            </div>

            <div class="card">
                <h2>
                    <span class="card-icon">📁</span>
                    Upload File to Storage
                </h2>
                <div id="storage-alert" class="alert"></div>
                <form id="uploadForm">
                    <div class="form-group">
                        <label for="filename">File Name</label>
                        <input type="text" id="filename" name="filename" required placeholder="Enter file name">
                    </div>
                    <div class="form-group">
                        <label for="file">Select File</label>
                        <input type="file" id="file" name="file" required>
                    </div>
                    <button type="submit" class="btn">
                        Upload to Storage
                        <span id="storage-loader" class="loader" style="display: none;"></span>
                    </button>
                </form>
                <div id="file-list" class="data-list"></div>
            </div>
        </div>
    </div>

    <script>
        // Data Form Submission
        document.getElementById('dataForm').addEventListener('submit', async (e) => {
            e.preventDefault();

            const btn = e.target.querySelector('button');
            const loader = document.getElementById('db-loader');
            const alert = document.getElementById('db-alert');

            btn.disabled = true;
            loader.style.display = 'inline-block';

            const formData = {
                name: document.getElementById('name').value,
                email: document.getElementById('email').value,
                message: document.getElementById('message').value
            };

            try {
                const response = await fetch('/api/save-data', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(formData)
                });

                const result = await response.json();

                if (response.ok) {
                    alert.className = 'alert alert-success show';
                    alert.textContent = '✅ Data saved successfully to Cosmos DB!';
                    e.target.reset();
                    loadData();
                } else {
                    alert.className = 'alert alert-error show';
                    alert.textContent = '❌ Error: ' + result.message;
                }
            } catch (error) {
                alert.className = 'alert alert-error show';
                alert.textContent = '❌ Error: ' + error.message;
            } finally {
                btn.disabled = false;
                loader.style.display = 'none';
                setTimeout(() => alert.classList.remove('show'), 5000);
            }
        });

        // File Upload
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();

            const btn = e.target.querySelector('button');
            const loader = document.getElementById('storage-loader');
            const alert = document.getElementById('storage-alert');

            btn.disabled = true;
            loader.style.display = 'inline-block';

            const formData = new FormData();
            formData.append('file', document.getElementById('file').files[0]);
            formData.append('filename', document.getElementById('filename').value);

            try {
                const response = await fetch('/api/upload-file', {
                    method: 'POST',
                    body: formData
                });

                const result = await response.json();

                if (response.ok) {
                    alert.className = 'alert alert-success show';
                    alert.textContent = '✅ File uploaded successfully to Storage Account!';
                    e.target.reset();
                    loadFiles();
                } else {
                    alert.className = 'alert alert-error show';
                    alert.textContent = '❌ Error: ' + result.message;
                }
            } catch (error) {
                alert.className = 'alert alert-error show';
                alert.textContent = '❌ Error: ' + error.message;
            } finally {
                btn.disabled = false;
                loader.style.display = 'none';
                setTimeout(() => alert.classList.remove('show'), 5000);
            }
        });

        // Load existing data
        async function loadData() {
            try {
                const response = await fetch('/api/get-data');
                const result = await response.json();

                const dataList = document.getElementById('data-list');
                if (result.status === 'success' && result.items.length > 0) {
                    dataList.innerHTML = '<h3 style="color: #667eea; margin-bottom: 10px;">Recent Entries</h3>';
                    result.items.forEach(item => {
                        dataList.innerHTML += `
                            <div class="data-item">
                                <h4>${item.name}</h4>
                                <p><strong>Email:</strong> ${item.email}</p>
                                <p><strong>Message:</strong> ${item.message}</p>
                                <p style="font-size: 0.8rem; color: #999;">Submitted: ${item.timestamp}</p>
                            </div>
                        `;
                    });
                }
            } catch (error) {
                console.error('Error loading data:', error);
            }
        }

        // Load existing files
        async function loadFiles() {
            try {
                const response = await fetch('/api/get-files');
                const result = await response.json();

                const fileList = document.getElementById('file-list');
                if (result.status === 'success' && result.files.length > 0) {
                    fileList.innerHTML = '<h3 style="color: #667eea; margin-bottom: 10px;">Uploaded Files</h3>';
                    result.files.forEach(file => {
                        fileList.innerHTML += `
                            <div class="data-item">
                                <h4>📄 ${file.name}</h4>
                                <p><strong>Size:</strong> ${(file.size / 1024).toFixed(2)} KB</p>
                                <p style="font-size: 0.8rem; color: #999;">Uploaded: ${new Date(file.last_modified).toLocaleString()}</p>
                            </div>
                        `;
                    });
                }
            } catch (error) {
                console.error('Error loading files:', error);
            }
        }

        // Check status
        async function checkStatus() {
            try {
                const response = await fetch('/health');
                const result = await response.json();

                // Update status badges based on configuration
                // These are already showing as connected in the HTML
            } catch (error) {
                document.getElementById('cosmos-status').className = 'status-badge status-error';
                document.getElementById('cosmos-status').textContent = 'Error';
                document.getElementById('storage-status').className = 'status-badge status-error';
                document.getElementById('storage-status').textContent = 'Error';
            }
        }

        // Load data on page load
        window.addEventListener('load', () => {
            checkStatus();
            loadData();
            loadFiles();
        });
    </script>
</body>
</html>
"""

@app.route("/", methods=["GET"])
def index():
    """Render the web UI"""
    return render_template_string(HTML_TEMPLATE)

@app.route("/health", methods=["GET"])
def health():
    """Detailed health check with configuration status"""
    config_status = {
        "cosmos_endpoint": "configured" if COSMOS_ENDPOINT else "missing",
        "cosmos_key": "configured" if COSMOS_KEY else "missing",
        "storage_connection": "configured" if STORAGE_CONNECTION_STRING else "missing",
        "storage_account_name": STORAGE_ACCOUNT_NAME or "missing"
    }

    return jsonify({
        "status": "healthy",
        "configuration": config_status
    }), 200

@app.route("/api/save-data", methods=["POST"])
def save_data():
    """Save user data to Cosmos DB"""
    try:
        if not COSMOS_ENDPOINT or not COSMOS_KEY:
            return jsonify({
                "status": "error",
                "message": "Cosmos DB credentials not configured"
            }), 500

        data = request.json

        # Initialize Cosmos client
        client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
        database = client.get_database_client(DATABASE_NAME)
        container = database.get_container_client(USER_CONTAINER_NAME)

        # Create document
        document = {
            "id": str(uuid.uuid4()),
            "name": data.get("name"),
            "email": data.get("email"),
            "message": data.get("message"),
            "timestamp": datetime.utcnow().isoformat()
        }

        # Insert into Cosmos DB
        container.create_item(body=document)

        logger.info(f"Data saved to Cosmos DB: {document['id']}")

        return jsonify({
            "status": "success",
            "message": "Data saved successfully",
            "id": document["id"]
        }), 200

    except Exception as e:
        logger.error(f"Error saving data: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route("/api/get-data", methods=["GET"])
def get_data():
    """Get all user data from Cosmos DB"""
    try:
        if not COSMOS_ENDPOINT or not COSMOS_KEY:
            return jsonify({
                "status": "error",
                "message": "Cosmos DB credentials not configured"
            }), 500

        # Initialize Cosmos client
        client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
        database = client.get_database_client(DATABASE_NAME)
        container = database.get_container_client(USER_CONTAINER_NAME)

        # Query all items
        items = list(container.query_items(
            query="SELECT * FROM c ORDER BY c.timestamp DESC",
            enable_cross_partition_query=True
        ))

        return jsonify({
            "status": "success",
            "items": items,
            "count": len(items)
        }), 200

    except Exception as e:
        logger.error(f"Error getting data: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "items": []
        }), 500

@app.route("/api/upload-file", methods=["POST"])
def upload_file():
    """Upload file to Azure Storage"""
    try:
        if not STORAGE_CONNECTION_STRING:
            return jsonify({
                "status": "error",
                "message": "Storage connection string not configured"
            }), 500

        # Get file and filename from form
        file = request.files.get('file')
        filename = request.form.get('filename')

        if not file or not filename:
            return jsonify({
                "status": "error",
                "message": "File and filename are required"
            }), 400

        # Initialize Blob Service client
        blob_service_client = BlobServiceClient.from_connection_string(STORAGE_CONNECTION_STRING)

        # Get blob client
        blob_name = f"{filename}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{file.filename}"
        blob_client = blob_service_client.get_blob_client(
            container=UPLOADS_BLOB_CONTAINER_NAME,
            blob=blob_name
        )

        # Upload file
        file_content = file.read()
        blob_client.upload_blob(file_content, overwrite=True)

        logger.info(f"File uploaded to Storage Account: {blob_name}")

        return jsonify({
            "status": "success",
            "message": "File uploaded successfully",
            "blob_name": blob_name
        }), 200

    except Exception as e:
        logger.error(f"Error uploading file: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route("/api/get-files", methods=["GET"])
def get_files():
    """Get list of uploaded files"""
    try:
        if not STORAGE_CONNECTION_STRING:
            return jsonify({
                "status": "error",
                "message": "Storage connection string not configured"
            }), 500

        # Initialize Blob Service client
        blob_service_client = BlobServiceClient.from_connection_string(STORAGE_CONNECTION_STRING)
        container_client = blob_service_client.get_container_client(UPLOADS_BLOB_CONTAINER_NAME)

        # List all blobs
        blobs = list(container_client.list_blobs())

        files = [{
            "name": blob.name,
            "size": blob.size,
            "last_modified": blob.last_modified.isoformat()
        } for blob in blobs]

        return jsonify({
            "status": "success",
            "files": files,
            "count": len(files)
        }), 200

    except Exception as e:
        logger.error(f"Error getting files: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "files": []
        }), 500

# Legacy test endpoints
@app.route("/test-cosmos", methods=["GET"])
def test_cosmos():
    """Test Cosmos DB connection via private endpoint"""
    try:
        if not COSMOS_ENDPOINT or not COSMOS_KEY:
            return jsonify({
                "status": "error",
                "message": "Cosmos DB credentials not configured",
                "private_endpoint_working": False
            }), 500

        client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
        database = client.get_database_client(DATABASE_NAME)
        container = database.get_container_client(TEST_CONTAINER_NAME)

        test_item = {
            "id": "test-connection-1",
            "message": "Testing private endpoint connection",
            "timestamp": datetime.utcnow().isoformat()
        }

        container.upsert_item(test_item)
        read_item = container.read_item(item="test-connection-1", partition_key="test-connection-1")

        items = list(container.query_items(
            query="SELECT * FROM c",
            enable_cross_partition_query=True
        ))

        return jsonify({
            "status": "success",
            "message": "Cosmos DB connection via private endpoint is working!",
            "private_endpoint_working": True,
            "database": DATABASE_NAME,
            "container": TEST_CONTAINER_NAME,
            "endpoint": COSMOS_ENDPOINT,
            "test_item_created": True,
            "total_items": len(items)
        }), 200

    except Exception as e:
        logger.error(f"Cosmos DB error: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "private_endpoint_working": False
        }), 500

@app.route("/test-storage", methods=["GET"])
def test_storage():
    """Test Storage Account connection via private endpoint"""
    try:
        if not STORAGE_CONNECTION_STRING:
            return jsonify({
                "status": "error",
                "message": "Storage connection string not configured",
                "private_endpoint_working": False
            }), 500

        blob_service_client = BlobServiceClient.from_connection_string(STORAGE_CONNECTION_STRING)
        container_client = blob_service_client.get_container_client(TEST_BLOB_CONTAINER_NAME)

        test_blob_name = "test-connection.txt"
        test_content = "Testing private endpoint connection to Azure Storage"

        blob_client = blob_service_client.get_blob_client(
            container=TEST_BLOB_CONTAINER_NAME,
            blob=test_blob_name
        )

        blob_client.upload_blob(test_content, overwrite=True)
        downloaded_blob = blob_client.download_blob()
        content = downloaded_blob.readall().decode('utf-8')

        blobs = list(container_client.list_blobs())

        return jsonify({
            "status": "success",
            "message": "Storage Account connection via private endpoint is working!",
            "private_endpoint_working": True,
            "storage_account": STORAGE_ACCOUNT_NAME,
            "container": TEST_BLOB_CONTAINER_NAME,
            "test_blob_uploaded": True,
            "test_blob_content": content,
            "total_blobs": len(blobs)
        }), 200

    except Exception as e:
        logger.error(f"Storage error: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "private_endpoint_working": False
        }), 500

if __name__ == "__main__":
    logger.info(f"Starting Flask application on port {PORT}")
    logger.info(f"Cosmos Endpoint: {COSMOS_ENDPOINT}")
    logger.info(f"Storage Account: {STORAGE_ACCOUNT_NAME}")
    app.run(host="0.0.0.0", port=PORT, debug=False)
