function [GmshStatus] = writeGmsh(fileName,meshOutput)


triangleMat = [meshOutput.facesBoundary meshOutput.boundaryMarker];
triangleMatSort = sortrows(triangleMat,4);

tetMat = [meshOutput.elements meshOutput.elementMaterialID];
tetMat = sortrows(tetMat,5);

fid = fopen(fileName,'wt');
fprintf(fid, '$MeshFormat \n2.2 0 8 \n$EndMeshFormat\n') ;

fprintf(fid,'\n$PhysicalNames\n');
labelledVols = max(meshOutput.elementMaterialID);

labelledSurfs = max(meshOutput.boundaryMarker);

fprintf(fid, '%d \n',labelledVols+labelledSurfs);


for i=1:max(meshOutput.boundaryMarker)
    fprintf(fid,'%d %d "%d"\n',2,i,i);
end

% Volume Physicalnames
for i=1:max(meshOutput.elementMaterialID)
    fprintf(fid,'%d %d "%d"\n',3,i,i);
end


fprintf(fid, '$EndPhysicalNames \n');

fprintf(fid, '$Nodes\n');
fprintf(fid,'%d\n',size(meshOutput.nodes,1));

for i =1:size(meshOutput.nodes,1)
      fprintf(fid, '%d %.16f %.16f %.16f\n',i,meshOutput.nodes(i,1),meshOutput.nodes(i,2),meshOutput.nodes(i,3));
end

fprintf(fid, '$EndNodes \n$Elements\n');
fprintf(fid,'%d\n',size(meshOutput.facesBoundary,1)+size(meshOutput.elements,1));

%Triangles
for i =1:size(meshOutput.boundaryMarker,1)
    fprintf(fid, '%d %d %d %d %d %d %d %d\n',i,2,2,triangleMatSort(i,4),triangleMatSort(i,4),triangleMatSort(i,1),triangleMatSort(i,2),triangleMatSort(i,3));
end

%Tets
for i =1:size(meshOutput.elements,1)
    fprintf(fid, '%d %d %d %d %d %d %d %d %d\n',size(meshOutput.boundaryMarker,1)+i,4,2,tetMat(i,5),tetMat(i,5),tetMat(i,1),tetMat(i,2),tetMat(i,3),tetMat(i,4));
end

fprintf(fid, '$EndElements\n');
fclose(fid);

GmshStatus = fprintf('Gmsh Version 2 ASCII written correctly');
end

