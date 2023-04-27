param(
    $Command
)

. ({ "/consult $Command" ; while ($true) { Read-Host } }) | des.exe