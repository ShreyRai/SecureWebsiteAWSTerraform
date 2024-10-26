# Flask Web Application Hosting on AWS

## Overview
This project demonstrates how to host a dynamic web application using Flask on an AWS EC2 instance. The application serves dynamic content and utilizes an S3 bucket for static assets, ensuring efficient content delivery.

## Table of Contents
- [Technologies Used](#technologies-used)
- [Setup Instructions](#setup-instructions)
- [Application Structure](#application-structure)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Technologies Used
- **AWS EC2**: To host the Flask application.
- **AWS S3**: For serving static assets.
- **Flask**: The web framework used to build the application.
- **Terraform**: For infrastructure as code (IaC) to provision AWS resources.
- **Amazon VPC**: For isolating the EC2 instance in private cloud

## Setup Instructions

### Prerequisites
- An AWS account.
- AWS CLI installed and configured.
- Terraform installed on your local machine.

### Deploying the Application
1. Clone this repository:
   ```bash
   git clone https://github.com/username/repo-name.git
   cd repo-name


