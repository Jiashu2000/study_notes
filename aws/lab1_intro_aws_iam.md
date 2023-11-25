# Lab 1: Introduction to AWS Identity and Access Management


## Objectives
After completing this lab, you will be able to:
- Explore IAM Users and Groups
- Inspect IAM policies applied to groups
- Follow a real-world scenario that adds users to groups and explores group permissions
- Locate and use the IAM sign-in URL
- Experiment with policies and service access

## LAB OVERVIEW
This lab provisions the following IAM resources for you to explore:
- Three users: 
    - user-1
    - user-2
    - user-3
- Three groups: with the following policies:
    - S3 Support: Read-Only access to Amazon Simple Storage Service (Amazon S3).
    - EC2 Support: Read-Only access to Amazon Elastic Compute Cloud (Amazon EC2).
    - EC2 Admin: Ability to View, Start, and Stop EC2 instances.

## Task 1: Explore IAM

The list below outlines the basic structure of an IAM policy:

- Effect indicates whether to Allow or Deny the permissions.
- Action specifies the API calls allowed to an AWS service (such as cloudwatch:ListMetrics).
- Resource defines the scope of entities covered by the policy rule (i.e., a specific Amazon S3 bucket, Amazon EC2 instance, or \*, which indicates any resource).

## Task 2: Use the IAM sign-in URL

