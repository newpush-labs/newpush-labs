## Packer-Proxmox Template for Cybersecurity Student Lab

This project streamlines the creation of Debian virtual machine (VM) templates for use in the cybersecurity student lab on Proxmox VE. The templates are specifically designed for vulnerability management exercises, allowing students to practice attack and defense techniques in a controlled environment.

### Key Features

* **Automated VM Creation:** Uses Packer to automatically create Debian VM templates.
* **Preseeding for Customization:**  Preseeding automates the installation process and allows for easy customization of the templates.
* **Cloud-Init Integration:** Cloud-init enables dynamic configuration of VMs deployed from the templates (e.g., setting hostnames, IP addresses).
* **Security-Focused:** Includes essential security tools like OpenVAS and Wazuh within Docker containers.
* **Easy Deployment:** Templates can be easily deployed on Proxmox VE.

### Requirements

* Packer 1.9.1+
* Proxmox VE 6.2+
* AWS account and IAM user with appropriate permissions (for AWS deployment)
* (Optional) Terraform for infrastructure provisioning

### How to Use

1. **Clone the Repository:**
   ```bash
   git clone git@bitbucket.org:newpush/student-lab.git
   ```

2. **Customize (Optional):**
   * Modify the `preseed.cfg` file for specific Debian installation options.
   * Update the `cloud.cfg` file, replacing the `ssh_authorized_keys` with your public keys.

3. **Build the Template:**
   ```bash
   packer build -var-file example-variables.pkrvars.hcl .
   ```
   Or rename `variables.auto.pkrvars.hcl.example` to `variables.auto.pkrvars.hcl` and run:
   ```bash
   packer build debian-12-proxmox.pkr.hcl
   ```
   Or
   ```bash
   packer build debian-12-aws.pkr.hcl
   ```

4. **Deploy in Proxmox VE:**
   * Right-click on the created template and select "Clone."
   * Choose between a full or linked clone (see notes below).

5. **Deploy in Proxmox VE:**
   * Use the AWS Management Console or CLI to launch an instance from the newly created AMI.

### Important Notes

* **Linked Clones:** Require less space but cannot run without the base template. Not compatible with LVM & ISCSI storage.
* **SSH Access:** Ensure your public SSH keys are added to `cloud.cfg` for passwordless `sudo` access as the `debian` user.

### Integration with the Student Lab

This project integrates seamlessly with the broader cybersecurity student lab environment:

* **Security Tools VM:** Hosts the Docker containers with security tools (OpenVAS, Wazuh) and the Portainer UI for container management.
* **Exercise VMs:** Deploy VMs from the templates with pre-configured vulnerabilities for student exercises.
* **Terraform:** Can be used to automate the provisioning of the lab infrastructure, including the Security Tools VM and initial tool installation.

### Contributing

Contributions are welcome! Feel free to open issues for suggestions or submit pull requests with code changes.
