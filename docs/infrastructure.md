# Understanding the Calcutta Madness Application

This application is a full-stack project designed to host and manage March Madness auctions. It uses modern web technologies and cloud infrastructure to deliver a scalable, serverless experience. Here's a breakdown of its components:

---

## 1. **The Gatsby Front End**

### What is Gatsby?
Gatsby is a framework for building **static websites**. Unlike traditional websites that generate pages dynamically on the server, Gatsby pre-generates all the pages at build time. This makes the site **fast**, **secure**, and **easy to deploy**.

### How It Works:
- **Static Site Generation (SSG):** Gatsby fetches data (e.g., from APIs or files) during the build process and creates static HTML, CSS, and JavaScript files.
- **React-Powered:** The front end is built with React, so it feels like a modern, interactive app.
- **Hosting:** The static files are uploaded to an S3 bucket and served via a CloudFront CDN for fast global delivery.

### Key Features in This App:
- **Authentication:** Users log in using AWS Cognito, which handles user accounts and sessions.
- **Dynamic Data:** Although the site is static, it fetches live data (e.g., auction details) from the backend APIs using JavaScript after the page loads.

---

## 2. **The API Gateway / Lambda Serverless Backend**

### What is Serverless?
Serverless means you don't manage servers. Instead, you write small functions (called **Lambdas**) that run on-demand in the cloud. AWS handles scaling, uptime, and maintenance.

### How It Works:
- **REST API:** The backend uses AWS API Gateway to expose REST endpoints. Each endpoint is linked to a Lambda function that performs specific tasks (e.g., creating an auction, placing a bid).
- **WebSocket API:** For real-time updates (e.g., live auction bidding), the app uses WebSocket APIs. These allow the server to push updates to connected clients instantly.
- **DynamoDB:** A NoSQL database stores auction data, user connections, and other app state.

### Key Features in This App:
- **REST API:** Handles user actions like creating auctions, fetching auction details, and placing bids.
- **WebSocket API:** Keeps all participants in sync during live auctions by broadcasting updates in real time.
- **Scalability:** AWS automatically scales the Lambdas to handle traffic spikes (e.g., during a popular auction).

---

## 3. **Terraform for Cloud Infrastructure**

### What is Terraform?
Terraform is a tool for managing cloud resources using code. Instead of clicking around in the AWS console, you define your infrastructure in configuration files. This makes it easy to automate, version, and share.

### How It Works:
- **Infrastructure as Code (IaC):** Terraform files describe all the AWS resources needed for the app (e.g., S3 buckets, API Gateway, DynamoDB tables, Lambda functions).
- **Deployment:** When you run `terraform apply`, Terraform creates or updates the resources in AWS to match the configuration.
- **State Management:** Terraform keeps track of the current state of your infrastructure, so it knows what changes to make.

### Key Features in This App:
- **S3 and CloudFront:** Hosts the Gatsby front end.
- **API Gateway and Lambda:** Configures the REST and WebSocket APIs.
- **DynamoDB:** Sets up the database tables for auctions and user connections.
- **Cognito:** Manages user authentication and authorization.

---

## How It All Fits Together

1. **User Interaction:**
   - A user visits the Gatsby front end, which is served from S3 and CloudFront.
   - They log in using Cognito and interact with the app (e.g., join an auction).

2. **Backend Communication:**
   - The front end calls the REST API (via API Gateway) to fetch or update data.
   - For live updates, the WebSocket API keeps the user in sync with other participants.

3. **Cloud Infrastructure:**
   - Terraform provisions and manages all the AWS resources, ensuring the app is scalable and reliable.

---

This design leverages the best of modern web development and cloud computing to deliver a fast, scalable, and cost-effective application.