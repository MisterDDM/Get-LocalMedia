# Get-LocalMedia

Find every media on this workstation and / or on the network

This script is capable of finding Movies, Documentaires and Series on every drive on this workstation and / or on mapped network shares. 
There must be a root folder called *Movie* or *Serie* or *Anime* for this script to work.
Example: E:\Movies or C:\Series and so on.
The files and folders structure must be formated in a certain way: 
Folder structure : 'K:\Movies_K\Extremely Wicked Shockingly Evil and Vile 2019 1080p'
File structure : 'Extremely Wicked Shockingly Evil and Vile 2019 1080p.mkv'
This script is depenend of Get-RootDrives. Without Get-RootDrives, this script won't work.

PARAMETER Kind
Is not mandatory. It accepts only matching values pre validated.

PARAMETER Find
Is not mandatory. By default it will find everything using a wildcard.

PARAMETER File
Is not Mandatory. If switch parameter is not set, it will set the parameter File as default.

PARAMETER Directory
Is not Mandatory. If switch parameter Directory is not set, it will set the default switch parameter File.

EXAMPLE
Get-LocalMedia
This will show all movies available on this workstation, usb drives and on network shares

EXAMPLE
Get-LocalMedia -Find 'Star' -Kind Movies -File
This will show all movies with the matching word Star.

EXAMPLE

glm star -fl
This will show all movies with the matching word Star.

EXAMPLE
Get-LocalMedia -Kind Series -File -Find 'Game of Thrones'

EXAMPLE
glm harry
This will show all movies where the name is like 'harry'

NOTES
Created by MisterDDM
This script is dependent of Get-RootDrives
