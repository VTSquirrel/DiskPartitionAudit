# Disk Partition Audit

This script will generate a report on the partition types (GPT or MBR) of a list of target devices.

#### Example

|Computer Name|BIOS    |Operating System  |       Version   |   Disk Number| Size (GB) |Partition Type|
|-------------| ----  |  ----------------   |      -------   |   -----------| ---------| --------------|
|DEVICE 1  |UEFI|    Microsoft Windows 10 Pro| 10.0.19042.0 |          0  |     954| GPT|           
|DEVICE 1  |UEFI|    Microsoft Windows 10 Pro| 10.0.19042.0|           1 |      119| MBR  |         
|DEVICE 2  |Offline| Offline |                 Offline |         Offline |  Offline| Offline  |

## Usage
### Parameters
* [Required] `$Target` - Text file (.txt) containing a list of devices to check
* [Optional] `$DisplayResults` - $true/$false. Indicate whether or not to display the report on screen once finished. **Default** = $true
* [Required] `$ExportToCsv` - $true/$false. Indicate whether or not to export the results to a CSV file. Defaults to the current directory of the script.
* [Optional] `$OutputDirectory` - The location to save the CSV report. The default is the current directory of the script.

#### Examples
```
.\DiskPartitionAudit.ps1 -Target "list.txt" -$ExportToCsv $true -OutputDirectory "C:\"
.\DiskPartitionAudit.ps1 -Target "list.txt" -DisplayResults $false -$ExportToCsv $true
```
