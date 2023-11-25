# Lab 2: Creating a VPC and Launching a Web Application in an Amazon EC2 Instance

## Objectives
After completing this lab, you will be able to:

- Create a new Amazon VPC with two public subnets
- Create an Internet Gateway
- Create a Route Table with a Public Route to the Internet
- Create a Security Group
- Launch an Amazon Elastic Compute Cloud (Amazon EC2) instance
- Configure an EC2 instance to host a web application using a user data script

## Task 1: Create a Virtual Private Cloud

In this task, you create a VPC, an Internet gateway, a Route Table with a public route to the Internet, and two public subnets in a two separate Availability Zones (AZs).

Amazon Virtual Private Cloud (Amazon VPC) enables you to launch AWS resources into a virtual network that you’ve defined. This virtual network closely resembles a traditional network that you’d operate in your own data center, with the benefits of using the scalable infrastructure of AWS.

An Internet gateway is a horizontally scaled, redundant, and highly available VPC component that allows communication between your VPC and the internet. It supports IPv4 and IPv6 traffic. It does not cause availability risks or bandwidth constraints on your network traffic.

After creating a VPC, you add subnets. Each subnet resides entirely within one Availability Zone and cannot span multiple Availability Zones. A subnet is a range of IP addresses in your VPC. You can launch AWS resources into a specified subnet. Use a public subnet for resources that must be connected to the internet, and a private subnet for resources that won’t be connected to the Internet. You will not use private subnets in this lab.

## Task 2: Create a VPC Security Group

A security group controls the traffic that is allowed to reach and leave the resources that it is associated with. For example, after you associate a security group with an EC2 instance, it controls the inbound and outbound traffic for the instance, similar to a firwall.

## Task 3: Launch Your Amazon EC2 Instance

In this task, you create an EC2 instance and provide a bootstrap script to install and configure the requirements for your web application. You also enable SSH (Secure Shell) access to the instance.