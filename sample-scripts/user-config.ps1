$global:ProjectRootPath = "{Enter full Path to repo root}"
$global:SolutionRoot = Resolve-Path $ProjectRootPath
$global:Env = "dev"
$global:EnvVarPath = Resolve-Path $solutionRoot\env
$global:SitesToStart = @("{Enter IIS Website 1 site name}", "{Enter IIS Website 2 site name}")
