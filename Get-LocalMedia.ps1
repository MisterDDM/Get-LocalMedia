Function Get-LocalMedia
{
<#
.SYNOPSIS
    Find every media on this workstation and / or on the network

.DESCRIPTION
    This script is capable of finding Movies, Documentaires and Series on every drive on this workstation and / or on mapped network shares. 
    There must be a root folder called *Movie* or *Serie* or *Anime* for this script to work.
    Example: E:\Movies or C:\Series and so on.
    The files and folders structure must be formated in a certain way: 
        Folder structure : 'K:\Movies_K\Extremely Wicked Shockingly Evil and Vile 2019 1080p'
        File structure : 'Extremely Wicked Shockingly Evil and Vile 2019 1080p.mkv'

    This script is depenend of Get-RootDrives. Without Get-RootDrives, this script won't work.

.PARAMETER Kind
    Is not mandatory. It accepts only matching values pre validated.

.PARAMETER Find
    Is not mandatory. By default it will find everything using a wildcard.

.PARAMETER File
    Is not Mandatory. If switch parameter is not set, it will set the parameter File as default.

.PARAMETER Directory
    Is not Mandatory. If switch parameter Directory is not set, it will set the default switch parameter File.

.EXAMPLE
    Get-LocalMedia
    This will show all movies available on this workstation, usb drives and on network shares

.EXAMPLE
    Get-LocalMedia -Find 'Star' -Kind Movies -File
    This will show all movies with the matching word Star.

.EXAMPLE
    glm star -fl
    This will show all movies with the matching word Star.

.EXAMPLE
    Get-LocalMedia -Kind Series -File -Find 'Game of Thrones'

.EXAMPLE
    glm harry
    This will show all movies where the name is like 'harry'

.NOTES
    Created by De Maeseneer Didier
    This script is dependent of Get-RootDrives
#>

    [CmdletBinding( DefaultParameterSetName = 'File', 
                    SupportsShouldProcess = $true, 
                    PositionalBinding = $false,
                    ConfirmImpact = 'Medium')]
    [Alias('glm')]
    #[OutputType([String])]

    Param
    (
        [Parameter( Mandatory = $false,
                    Position = 0,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true,
                    ValueFromRemainingArguments = $false )]
        [ValidateNotNullOrEmpty()]
        [Alias("fd")]
        [string[]]$Find = '*',
                
        [Parameter( Mandatory = $false,
                    Position = 1,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true,
                    ValueFromRemainingArguments = $false,
                    HelpMessage = 'You have to specify a kind of media you are searching for' )]
        [validateSet( 'Anime-Movies' , 'Anime-Series' , 'Documentaires' , 'Movies', '3D_Movies' , 'Series' , 'All-Movies' )]
        [ValidateNotNullOrEmpty()]
        [Alias("k")]
        [string]$Kind = 'All-Movies',

        [Parameter( Mandatory = $false,
                    Position = 2,
                    ParameterSetName = 'File', 
                    ValueFromPipeline = $false,
                    ValueFromPipelineByPropertyName = $false,
                    ValueFromRemainingArguments = $false )]
        [Alias("fl")]
        [switch]$File,

        [Parameter( Mandatory = $false,
                    Position = 2,
                    ParameterSetName = 'Directory', 
                    ValueFromPipeline = $false,
                    ValueFromPipelineByPropertyName = $false,
                    ValueFromRemainingArguments = $false )]
        [Alias("dir")]
        [switch]$Directory,

        [Parameter( Mandatory=$false,
                    ValueFromPipeline = $false,
                    ValueFromPipelineByPropertyName = $false,
                    ValueFromRemainingArguments = $false )]
        [Alias("sw")]
        [switch]$ShowAllProperties,

        [Parameter( Mandatory=$false,
                    ValueFromPipeline = $false,
                    ValueFromPipelineByPropertyName = $false,
                    ValueFromRemainingArguments = $false )]
        [Alias("ex")]
        [switch]$Explore

    )

    Begin
    {

        $ThisYear = (Get-Date).Year
        $Format = 'dd/MM/yyyy HH:mm:ss:fff'

        if ( $PSBoundParameters['Verbose'] ) 
        {
            Write-Verbose "$(Get-Date -Format $Format) Verbose is turned on"
        }

        $RootDrives = Get-RootDrives -Folder $Kind
        $Drives = $RootDrives.FullName

        $4K = '2160p','4K'
        $FullHD = '1080p','FullHD'
        $HD = '720p','HD'
        $LD = '480p','LD'
        $Dimensions = $4K,$FullHD,$HD,$LD
    
    }
    Process
    {
        if ($pscmdlet.ShouldProcess( "Trying to find $Find as $Kind" ))
        {
            $Find | ForEach-Object {

                $Search = $_ -replace(' ','*')
                Write-Verbose "$(Get-Date -Format $Format) Replaced spaces with stars $Search"
                
                if ( -not $PSBoundParameters['File'] -and -not $PSBoundParameters['Directory'] )
                {
                    $PSBoundParameters.Add('File',$true)
                }

                switch ( $PSBoundParameters.Keys ) 
                {
                    Directory
                    {
                        Write-Verbose "$(Get-Date -Format $Format) Searching for Directories"
                        $SearchingFor = Get-ChildItem -Path $Drives -Recurse -Directory -Filter "*$Search*"
                        $Data = $SearchingFor | Where-Object { 
                            $_.Name -notmatch '^Subs' -and 
                            $_.Name -notmatch '^Subtitle*' -and 
                            $_.Name -notmatch 'Film Français$' -and 
                            $_.Name -notmatch 'Collection \d{3,4}p' 
                        }
                    }

                    File
                    {
                        Write-Verbose "$(Get-Date -Format $Format) Searching for files"
                        $SearchingFor = Get-ChildItem -Path $Drives -Recurse -File -Filter "*$Search*" -Include '*.mkv','*.mp4','*.avi','*.iso','*.m2ts','*.m4v' 
                        $Data = $SearchingFor
                    }
                }

                if ( -not $Data ) 
                { 
                    Write-Warning "$(($Find -replace '[*]',' ').TrimStart().TrimEnd()) $('Not found')"
                    Break
                }

                try 
                {
                    Write-Verbose "$(Get-Date -Format $Format) Entering Loop"
                    Write-Verbose "$(Get-Date -Format $Format) ."
                    for ( $i = 0; $i -lt $Data.count; $i++ ) 
                    {
                        if ( $Data[$i].Name -match  '^(?:(?<ShortName>.*)\s(?<Year>\d{4}).*\s(?<Quality>\d{3,4}p{1})\s(?<Dimension>3D))' )
                        {
                            $ShortName = $Matches['ShortName'] 
                            $Year = $Matches['Year']
                            $Quality = $Matches['Quality']
                            $Dimension = ($Dimensions | Where-Object { $_ -like $Quality })[1] + ' ' + $Matches['Dimension']
                        }
                        
                        elseif ( $Data[$i].Name -match '^(?:(?<ShortName>.*)\s(?<Year>\d{4}).*\s(?<Quality>\d{3,4}p{1}))' )  
                        { 
                            $ShortName = $Matches['ShortName'] 
                            $Year = $Matches['Year']
                            $Quality = $Matches['Quality']
                            $Dimension = ($Dimensions | Where-Object { $_ -like $Quality })[1]
                        }

                        elseif ( $Data[$i].Name -match '^(?:(?<ShortName>.*)\s(?<Quality>\d{3,4}p{1}).*\s(?<Year>\d{4}))' ) 
                        { 
                            $ShortName = $Matches['ShortName'] 
                            $Year = $Matches['Year']
                            $Quality = $Matches['Quality']
                            $Dimension = ($Dimensions | Where-Object { $_ -like $Quality })[1]
                        }

                        elseif ( $Data[$i].Name -match '^(?:(?<ShortName>.*)\s(?<Quality>\d{3,4}p{1}))' ) 
                        { 
                            $ShortName = $Matches['ShortName'] 
                            $Year = 0
                            $Quality = $Matches['Quality'] 
                            $Dimension = ($Dimensions | Where-Object { $_ -like $Quality })[1]
                        }

                        elseif ( $Data[$i].Name -match '^(?:(?<ShortName>.*)\s(?<Year>\d{4}))' ) 
                        { 
                            $ShortName = $Matches['ShortName'] 
                            $Year = $Matches['Year']
                            $Quality = '-'
                        }

                        else 
                        { 
                            $ShortName = $Data[$i].FullName
                            $Year = 0
                            $Quality = 0
                        }
                        
                        if ( $Year -gt '1920' -and $Year -le $ThisYear ) 
                        { 
                            $Year = $Year
                        }

                        else 
                        { 
                            $Year = 0
                        }
                        
                        Write-Verbose "$(Get-Date -Format $Format) ShortName $ShortName"
                        Write-Verbose "$(Get-Date -Format $Format) Year $Year"
                        Write-Verbose "$(Get-Date -Format $Format) Quality $Quality"
                        Write-Verbose "$(Get-Date -Format $Format) Dimension $Dimension"
                        
                        switch ( $PSBoundParameters.Keys ) 
                        {
                            Directory
                            {

                                $FolderSize = $( Get-ChildItem $Data[$i].Fullname -Recurse -Force | Measure-Object -Property Length -Sum ) 
                                if ( $FolderSize.Sum -lt 1MB ) 
                                { 
                                    $Size = [System.Math]::Round(($FolderSize.Sum / 1Kb),2)
                                    $Unit = 'KB'
                                }
                                elseif ( $FolderSize.Sum -lt 1GB ) 
                                { 
                                    $Size = [System.Math]::Round(($FolderSize.Sum / 1Mb),2)
                                    $Unit = 'MB'
                                }
                                elseif ( $FolderSize.Sum -lt 1TB ) 
                                { 
                                    $Size = [System.Math]::Round(($FolderSize.Sum / 1Gb),2)
                                    $Unit = 'GB'
                                }

                                if ( [bool]( Get-ChildItem $Data[$i].FullName -Recurse -Force -Include '*.srt','*.idx','*.str','*.sub') ) 
                                {
                                    $SubTitles = 'Yes'
                                }
                                else 
                                { 
                                    $SubTitles = 'No' 
                                }

                                $Root = $Data[$i].Root
                                $Parent = $Data[$i].Parent
                                $FullName = $Data[$i].FullName
                                if ( $FullName -match '\w{1}\:\\\w{1,}\\' ) { $Label = ( $RootDrives | Where-Object { $_.FullName -like $Matches[0].TrimEnd('\') }).Label }
                                $Name = $Data[$i].Name
                                $BaseName = $Data[$i].BaseName
                                $CreationTime = $Data[$i].CreationTime.ToString('dd/MM/yyyy HH:mm:ss')

                                Write-Verbose "$(Get-Date -Format $Format) Subtitles $SubTitles"
                                Write-Verbose "$(Get-Date -Format $Format) Root $Root"
                                Write-Verbose "$(Get-Date -Format $Format) Parent $Parent"
                                Write-Verbose "$(Get-Date -Format $Format) FullName $FullName"
                                Write-Verbose "$(Get-Date -Format $Format) Label $Label"
                                Write-Verbose "$(Get-Date -Format $Format) Name $Name"
                                Write-Verbose "$(Get-Date -Format $Format) BaseName $BaseName"
                                Write-Verbose "$(Get-Date -Format $Format) Size $Size"
                                Write-Verbose "$(Get-Date -Format $Format) Unit $Unit"                                
                                Write-Verbose "$(Get-Date -Format $Format) CreationTime $CreationTime"

                            }
                        
                            File
                            {
                                if ( $Data[$i].Length -lt 1Mb ) 
                                { 
                                    $Size = [System.Math]::Round(($Data[$i].Length / 1Kb),2)
                                    $Unit = 'KB'
                                }
                                elseif ( $Data[$i].Length -lt 1Gb ) 
                                {
                                    $Size = [System.Math]::Round(($Data[$i].Length / 1Mb),2)
                                    $Unit = 'MB'
                                }
                                elseif ( $Data[$i].Length -lt 1Tb ) 
                                { 
                                    $Size = [System.Math]::Round(($Data[$i].Length / 1Gb),2)
                                    $Unit = 'GB'
                                } 

                                Write-Verbose "$(Get-Date -Format $Format) Size $Size"
                    
                                if ( [bool](( Get-ChildItem $Data[$i].Directory -Recurse -Force ).Extension | Where-Object { $_ -like '.srt' -or $_ -like '.sub' -or $_ -like '.idx' -or $_ -like '.sub' }) ) 
                                {
                                    $SubTitles = 'Yes'
                                }
                                else 
                                { 
                                    $SubTitles = 'No' 
                                } 

                                $Root = $Data[$i].Directory.Root
                                $Parent = $Data[$i].Directory.Parent
                                $FullName = $Data[$i].Directory.FullName
                                if ( ${FullName} -match '\w{1}\:\\\w{1,}\\' ) { $Label = ( $RootDrives | Where-Object { $_.FullName -like $Matches[0].TrimEnd('\') }).Label }
                                $Name = $Data[$i].Name
                                $BaseName = $Data[$i].BaseName
                                $CreationTime = $Data[$i].CreationTime.ToString('dd/MM/yyyy HH:mm:ss')
                                $Extension = $Data[$i].Extension

                                Write-Verbose "$(Get-Date -Format $Format) Subtitles $SubTitles"
                                Write-Verbose "$(Get-Date -Format $Format) Root $Root"
                                Write-Verbose "$(Get-Date -Format $Format) Parent $Parent"
                                Write-Verbose "$(Get-Date -Format $Format) FullName $FullName"
                                Write-Verbose "$(Get-Date -Format $Format) Label $Label"
                                Write-Verbose "$(Get-Date -Format $Format) Name $Name"
                                Write-Verbose "$(Get-Date -Format $Format) BaseName $BaseName"
                                Write-Verbose "$(Get-Date -Format $Format) Size $Size"
                                Write-Verbose "$(Get-Date -Format $Format) Unit $Unit" 
                                Write-Verbose "$(Get-Date -Format $Format) CreationTime $CreationTime"
                                Write-Verbose "$(Get-Date -Format $Format) Extension $Extension"
                            }
                        }

                        if ( -not $PSBoundParameters['Verbose'] -and -not $PSBoundParameters['Explore'] ) 
                        {
                            $Object = [PSCustomObject][ordered]@{
                                Name = [string]$Name
                                BaseName = [string]$BaseName
                                ShortName = [string]$ShortName
                                Year = [int]$Year
                                Quality = [string]$Quality
                                Dimension = [string]$Dimension
                                Label = [string]$Label
                                Size = [double]$Size
                                Unit = [string]$Unit
                                SubTitles = [string]$SubTitles
                                CreationTime = [string]$CreationTime
                                Root = [string]$Root
                                Parent = [string]$Parent
                                FullName = [string]$FullName
                            }

                            if ( -not $PSBoundParameters['ShowAllProperties'] ) 
                            {
                                $Object.PSObject.TypeNames.Insert(0,'Movie')
                            } 

                            if ( $PSBoundParameters['File']  ) 
                            {
                                Add-Member -MemberType NoteProperty -Name 'Extension' -Value $Extension -InputObject $Object
                            }
                        
                            Write-Output $Object 
                            Remove-Variable Name,ShortName,Year,Quality,Dimension,Size,Unit,SubTitles,CreationTime,Root,Parent,FullName,Extension -ErrorAction SilentlyContinue
                        }
                        if ($PSBoundParameters['Explore'])
                        {
                            Start-Process explorer.exe -ArgumentList ${FullName}
                        }
                    }
                    Write-Verbose "$(Get-Date -Format $Format) ."
                    Write-Verbose "$(Get-Date -Format $Format) Loop ended"
                }
                Catch 
                { 
                    if ( $Error[0] ) 
                    { 
                        $Error[0].Exception.Message 
                    } 
                }
            }
        }
    }
    End
    {
    }
}