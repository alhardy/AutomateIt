$global:ProjectRootPath = "E:\Source\MySource-Git\AutomateIt\examples\AutomateIt.Example"
$global:SolutionRoot = Resolve-Path $ProjectRootPath
$global:Env = "dev"
$global:EnvVarPath = Resolve-Path $solutionRoot\env
$global:SitesToStart = @("AutomateItWeb", "AutomateItWebTwo")
