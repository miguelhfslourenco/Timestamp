baseFile=$1
if [ -z $baseFile ]
then
	echo "Missing input file..."
	exit
fi
echo -e "0)List all resources segregated by Project\n1)List all Folders\n2)List content of specific folder ID\n3)Count of resource types by folder\n4)Export all resources segregated by folder"
read -p "Choose one option:" option
echo
if [ "$option" == "0" ]
then
	for project in $(jq -r '.[]|select((.assetType != null) and (.assetType=="compute.googleapis.com/Project")).displayName' $baseFile)
	do
		#echo $project
		mkdir -p projects/$project
		echo "----------$project----------" > projects/$project/listResources4$project.txt
		#echo "----------$project----------" > projects/$project/listDetailedResources4$project.txt
		echo "----------$project----------" > tmp
		jq -r --arg project "$project" '.[]|select((.parentFullResourceName != null) and (.parentFullResourceName|test($project)))' $baseFile >> projects/$project/listResources4$project.json
		jq -r --arg project "$project" '.[]|select((.parentFullResourceName != null) and (.parentFullResourceName|test($project)))|"-----  \(.assetType)"' $baseFile |sort -u >> projects/$project/listResources4$project.txt
		#jq -r --arg project "$project" '.[]|select((.parentFullResourceName != null) and (.parentFullResourceName|test($project)))|if (.additionalAttributes != null) then "  -----\(.assetType)\n\t\(.additionalAttributes)\n" else "  -----\(.assetType)\n" end' $baseFile >> projects/$project/listDetailedResources4$project.txt
		jq -r --arg project "$project" '.[]|select((.parentFullResourceName != null) and (.parentFullResourceName|test($project)))|if (.additionalAttributes != null) then "  -----type: \(.assetType)\n       name: \(.displayName)\n       location: \(.location)\n       state: \(.state)\n       machineType: \(.additionalAttributes.machineType)\n       internalIPs: \(.additionalAttributes.internalIPs)\n       network: \(.additionalAttributes.networkInterfaceNetworks[0])\n" else "  -----type: \(.assetType)\n" end' $baseFile >> projects/$project/listDetailedResources4$project.txt
		#eliminar duplicados
		#awk -v RS= -v ORS="\n\n" '!seen[$0]++' projects/$project/listDetailedResources4$project.txt > tmp && mv tmp projects/$project/listDetailedResources4$project.txt
		awk -v RS= -v ORS="\n\n" '
		  {
		    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", $0)
		    count[$0]++
		  }
		  END {
		    for (block in count){
		      print block "\ncount: " count[block]
			}
		  }
		' projects/$project/listDetailedResources4$project.txt >> tmp && mv tmp projects/$project/listDetailedResources4$project.txt
	done
elif [ "$option" == "1" ]
then
	echo "-----Listing all Folders-----"
	jq -r '.[]|select(.assetType=="cloudresourcemanager.googleapis.com/Folder")|"\(.displayName) (\(.name))"' $baseFile |sed 's|//cloudresourcemanager.googleapis.com/folders||g'
elif [ "$option" == "2" ]
then
	echo "-----List of resource types inside specific folder-----"
	read -p "Insert folder ID:" folderID
	jq -r --arg folderID "$folderID" '.[]|select((.folders != null) and (.folders[]| contains($folderID))).assetType' $baseFile |sort -u
elif [ "$option" == "3" ]
then
	echo "-----Count of resource types by folder-----"
	read -p "Insert folder ID:" folderID
	#669859303107
	for resource in $(jq -r --arg folderID "$folderID" '.[]|select((.folders != null) and (.folders[]| contains($folderID))).assetType' $baseFile |sort -u)
	do
		echo "$resource: $(jq -r --arg folderID "$folderID" '.[]|select((.folders != null) and (.folders[]| contains($folderID))).assetType' $baseFile |grep $resource |wc -l)"
	done
elif [ "$option" == "4" ]
then
	echo "-----Exporting all resources segregated by folder-----"
	for folderID in $(jq -r '.[]|select((.assetType != null) and (.assetType=="cloudresourcemanager.googleapis.com/Folder")).name' $baseFile |sed 's|//cloudresourcemanager.googleapis.com/folders/||g')
	do
		folderName=$(jq -r --arg folderID "$folderID" '.[]|select((.assetType != null) and (.assetType=="cloudresourcemanager.googleapis.com/Folder") and (.name|test($folderID))).displayName' $baseFile)
		mkdir -p folders/$folderName
		#echo "----------$folder----------" > folders/$folder/listResources4$folder.txt
		jq -r --arg folderID "$folderID" '.[]|select((.folders != null) and (.folders[]| contains($folderID)))' $baseFile >> folders/$folderName/listResources4$folderID.json
	done
else
	echo "Unknown option"
fi
