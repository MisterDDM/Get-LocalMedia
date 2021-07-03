Function Get-RootDrives
{
<#
.SYNOPSIS
    Find Media root folders for Get-LocalMedia.

.DESCRIPTION
    _To complete_

.EXAMPLE
    Get-RootDrives -Folder 3D_Movies

    RootDrive   : M:
    FullName    : M:\3D_Movies
    Description : Local Fixed Disk
    FileSystem  : NTFS
    TotalSizeGB : 3726
    FreeSpaceGB : 538

    ...

.EXAMPLE
    Get-RootDrives -Folder Movies

    RootDrive   : F:
    FullName    : F:\Movies_F
    Description : Local Fixed Disk
    FileSystem  : NTFS
    TotalSizeGB : 3726
    FreeSpaceGB : 412

    ...

.NOTES
    Created by MisterDDM

#>
    [CmdletBinding( SupportsShouldProcess=$true, 
                    PositionalBinding=$false )]
    [Alias('grd')]
    [OutputType([String])]
    Param
    (
        [Parameter( Mandatory = $true ,
                    ValueFromPipeline = $true ,
                    ValueFromPipelineByPropertyName = $true )]
        [ValidateSet( 'Anime-Movies', 'Anime-Series', 'Documentaires', 'Movies', '4K_Movies', '3D_Movies', 'Series', 'All-Movies' )]
        [Alias('f')]
        [String]$Folder

    )
    
    Begin
    {
        $LogicalDrives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -LT 5 }
        
    }

    Process
    {
        if ($pscmdlet.ShouldProcess($Folder))
        {
            $LogicalDrives | ForEach-Object {
        
                $RootDrive = $_.DeviceID    

                if ( $PSBoundParameters['Folder'] -like 'All-Movies' )
                {
                    $SearchFor = '*Movie*'
                    $Filter = 'Anime_Manga'
                    $RootFolder = @()
                    $RootFolder += Get-ChildItem $RootDrive -Force -Directory -Filter $SearchFor | Where-Object { $_.Name -NotLike 'Personal*' }
                    $RootFolder += Get-ChildItem (Get-ChildItem $RootDrive -Force -Directory -Filter $Filter ).FullName -Force -Directory -Filter $SearchFor
                }

                if ($PSBoundParameters['Folder'].StartsWith('Anime') ) 
                {
                    if ( $PSBoundParameters['Folder'].EndsWith('Movies') )
                    {
                        $SearchFor = '*Movie*'
                        $Label = 'Anime Movies'
                        $Filter = 'Anime_Manga'
                    }
                    if ( $PSBoundParameters['Folder'].EndsWith('Series') ) 
                    {
                        $SearchFor = '*Series*'
                        $Label = 'Anime Series'
                        $Filter = 'Anime_Manga'
                    }

                    $RootFolder = Get-ChildItem (Get-ChildItem $RootDrive -Force -Directory -Filter $Filter).FullName -Force -Directory -Filter $SearchFor
                }

                else 
                {
                    if ( $PSBoundParameters['Folder'] -like 'Movies' )
                    {
                        $SearchFor = '*Movie*'
                    }

                    if ( $PSBoundParameters['Folder'] -like '3D_Movies' ) 
                    {
                        $SearchFor = '3D_Movies'
                    }
                    
                    if ( $PSBoundParameters['Folder'] -like '4K_Movies' ) 
                    {
                        $SearchFor = '4K_Movies'
                    }

                    if ( $PSBoundParameters['Folder'] -like 'Series' ) 
                    {
                        $SearchFor = '*Series*'
                    }

                    if ( $PSBoundParameters['Folder'] -like 'Documentaires' ) 
                    {
                        $SearchFor =  '*Documentaire*'
                    }
                    
                    $RootFolder = Get-ChildItem $RootDrive -Force -Directory -Filter $SearchFor | Where-Object { $_.Name -NotLike 'Personal*' }
                }

                $Description = $_.Description
                $FileSystem = $_.FileSystem
                $TotalSizeGB = $_.Size / 1GB -as [int32]
                $FreeSpaceGB = $_.FreeSpace / 1GB -as [int32]     

                $RootFolder | ForEach-Object {
                    
                    $FullName = $_.FullName
                    $Name = $_.Name

                    switch -Regex ($Name)
                    {
                        '.*Movies_\w{1}'
                        {
                            $Label = 'Movies'
                        }
                        '.*Movie_Collections'
                        {
                            $Label = 'Ology'
                        }
                        '.*\d{1}K.*'
                        {
                            $Label = '4K'
                        }
                        '.*\d{1}D.*'
                        {
                            $Label = '3D'
                        }
                        '.*Series_\w{1}'
                        {
                            $Label = 'Series'
                        }
                    }

                    [PSCustomObject][Ordered]@{
                        RootDrive = $RootDrive
                        FullName = $FullName
                        Name = $Name
                        Description = $Description
                        Label = $Label
                        FileSystem = $FileSystem 
                        TotalSizeGB = $TotalSizeGB
                        FreeSpaceGB = $FreeSpaceGB              
                    }    
                }
            }            
        }
    }
    End
    {
    }
}
