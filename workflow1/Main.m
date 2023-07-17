clear
clc
close all

%% import stl file
fileName = 'STL_afterImageProcessing_v1.stl';
[stlStruct] = import_STL(fileName);

F=stlStruct.solidFaces{1};
V=stlStruct.solidVertices{1};

% Merging Vertices (nodes are not merged when importing stl)
[Fagg,Vagg]=mergeVertices(F,V);

% Check if STL is watertight
mesh = surfaceMesh(Vagg,Fagg);
TF = isWatertight(mesh);

% Visualisation
cFigure; 
gpatch(Fagg,Vagg,'w','k');
axisGeom;

%% Smooth the triangulated surface (to remove "voxel" artifact)
% Method 1 (MATLAB file exchange)
voxelSize = 1;
DisplTol = 0.01;
IterTol = 700;
Vagg = SurfaceSmooth(Vagg, Fagg, voxelSize,DisplTol,IterTol);

% Method 2 (GIBBON toolbox)
% nSteps = 4;
% cPar2.Method='HC'; %Smooth method: Humphreys-Classes smoothing
% cPar2.n=nSteps; %Number of iterations
% [Vagg]=patchSmooth(Fagg,Vagg,[],cPar2);

stlfig = cFigure; 
gpatch(Fagg,Vagg,'w','k');
axisGeom;
axis off
view([92,13])

% Export STL
%patch2STL('remeshedAgg.stl',Vagg,Fagg,[],'RemeshedAgg');

%% Create cylinder
cFigure
inputStruct.cylRadius=150;
inputStruct.numRadial=150;
inputStruct.cylHeight=430;
inputStruct.numHeight=10;
inputStruct.meshType='tri';

% Derive patch data for a cylinder
[F,V]=patchcylinder(inputStruct);
V(:,3) = V(:,3)+inputStruct.cylHeight/2;
V(:,1) = V(:,1)+inputStruct.cylRadius;
V(:,2) = V(:,2)+inputStruct.cylRadius;

%% Cylinder remeshing
optionStruct3.nb_pts=size(V,1); %Set desired number of points
optionStruct3.disp_on=0; % Turn off command window text display
optionStruct3.pre.max_hole_area=400000; %Max hole area for pre-processing step
optionStruct3.pre.max_hole_edges=400000; %Max number of hole edges for pre-processing step
[Fcyl,Vcyl]=ggremesh(F,V,optionStruct3);

%% Detect surface features
%Angular threshold in radians
a=(45/180)*pi;
G=patchFeatureDetect(Fcyl,Vcyl,a);

%% Visualiza patch data
Eb=patchBoundary(F,V);
hold on;
title('Geogram remeshed and closed');
gpatch(Fcyl,Vcyl,G,'k',0.5);
axisGeom;
camlight headlight;
gdrawnow;

%% Surface and volumetric Meshing using TetGen
% Join surface sets
[F,V,C]=joinElementSets({Fcyl,Fagg},{Vcyl,Vagg});
C(1:size(G,1))=G;
C(size(G,1)+1:size(C,1)) = 4*ones(size(C,1)-size(G,1),1);

% Find interior points
[V_region1]=getInnerPoint({Fcyl,Fagg},{Vcyl,Vagg});
[V_region2]=getInnerPoint(Fagg,Vagg);
V_regions=[V_region1; V_region2];

% Volume parameters
[vol1]=tetVolMeanEst(Fcyl,Vcyl);
[vol2]=tetVolMeanEst(Fagg,Vagg);
regionTetVolumes=[vol1 vol2]; %Element volume settings
stringOpt='-pq1.2AaY'; %Tetgen options
modelName = 'test';

% Mesh inputs
% Create tetgen input structure
inputStruct.stringOpt=stringOpt; %Tetgen options
inputStruct.Faces=F; %Boundary faces
inputStruct.Nodes=V; %Nodes of boundary
inputStruct.faceBoundaryMarker=C;
inputStruct.regionPoints=V_regions; %Interior points for regions
inputStruct.regionA=regionTetVolumes; %Desired tetrahedral volume for each region
inputStruct.modelName = modelName;

% Mesh model using tetrahedral elements using tetGen
[meshOutput]=runTetGen(inputStruct); %Run tetGen

% Mesh Output
E=meshOutput.elements; %The elements
V=meshOutput.nodes; %The vertices or nodes
CE=meshOutput.elementMaterialID; %Element material or region id
for i = 1:size(CE,1)
    if CE(i,1)~= -2
        CE(i,1) = 2;
    else
        CE(i,1) = 1;
    end
end
meshOutput.elementMaterialID = CE;
Fb=meshOutput.facesBoundary; %The boundary faces
Cb=meshOutput.boundaryMarker; %The boundary markers

%% Visualization
hf=cFigure;
subplot(1,2,1); 
hold on;
hp(1)=gpatch(Fcyl,Vcyl,'gw','k',0.5,0.5);
hold on;
gpatch(Fagg,Vagg,'w','k');
title('Surface Meshes');
fontSize=12;
axisGeom(gca,fontSize); camlight headlight;
hs=subplot(1,2,2); hold on;
title('Multi-domain tetrahedral mesh','FontSize',fontSize);

% Visualizing using |meshView|
optionStruct.hFig=[hf,hs];
meshView4(meshOutput,optionStruct);
axisGeom(gca,fontSize);
gdrawnow;

%% Write version 2 ASCII .msh mesh format 
fileName = 'ConcreteMultiDomain.msh';
[status] = writeGmsh(fileName,meshOutput);

%% Convert .msh to .xdmf via meshio
runString=['"C:\Windows\System32\wsl.exe" ','python3',' "../../../../../../../../../../../../../../../../mnt/c/Users/homeuser/Desktop/Postdoc/FEniCS/MFront/Github_repoUrgent/ConvertGmshToXdmf.py"'];
[runStatus,runOut]=system(runString,'-echo');
