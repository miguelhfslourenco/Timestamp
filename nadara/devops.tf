provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/renantis"
  personal_access_token = "BdToGKK2bx3LX2JmZ7VG078Wqm8qMnnadZZPeFpiMq5cIsfhxPqUJQQJ99BDACAAAAALws2MAAASAZDO2CdT"
}

##########
##DEVOPS##
##########
resource "azuredevops_project" "dataplatform" {
  name       = "data-platform"
#  description = <<-EOT
#            This is a generic project which holds standard documentation, company compliance.
#            Nothing related to code for specific projects.
#            EOT
  visibility = "private"
  lifecycle {
    ignore_changes = [description]
  }
}

resource "azuredevops_git_repository" "git_dp_repo" {
  name            = "dataplatform"
  project_id      = azuredevops_project.dataplatform.id
  default_branch  = "refs/heads/master"
  initialization {
    init_type = "Clean"
  }
}

resource "null_resource" "git_branches" {
  depends_on = [azuredevops_git_repository.git_dp_repo]

  provisioner "local-exec" {
    command = <<EOT
      git clone https://dev.azure.com/renantis/dataplatform/_git/data-platform
      cd data-platform
      git checkout -b develop
      git push origin develop
      git checkout -b staging
      git push origin staging
      git checkout -b master
      git push origin master
    EOT
  }
}