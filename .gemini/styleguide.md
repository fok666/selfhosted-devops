# Terraform & Infrastructure Style Guide

## Terraform (HCL)
- **Formatting**: Always run `terraform fmt` before committing.
- **Naming Conventions**:
  - Use `snake_case` for all resource names, data sources, and variables.
  - Use descriptive names (e.g., `aws_instance.build_server` instead of `aws_instance.server`).
- **Variables**:
  - Always provide a `description` and `type` for every variable in `variables.tf`.
  - Use `terraform.tfvars` for local values, do not commit sensitive values.
- **Modules**:
  - Keep modules focused and reusable.
  - Expose outputs that are likely to be used by consumers (IDs, ARNs, endpoints).
- **State**:
  - Never commit specific remote state configurations that contain credentials.

## Documentation (Markdown)
- Maintain `README.md` files for each module explaining Inputs, Outputs, and Dependencies.
- Use clear headings and code blocks for examples.

## Directory Structure
- Follow the standard structure: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
- Organize distinct environments or cloud providers into separate directories (as seen with `aws/`, `azure/`).
