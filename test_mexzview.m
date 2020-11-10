clear all
zv=Mexzview();

%%
% zv.removeShape()
[yg,xg] = ndgrid(linspace(-1,1,64)*pi/2,linspace(-1,1,64)*pi);
color=abs(sin(4*yg).*sin(4*xg).*sin(4*yg));
xyz = cat(3,cos(yg).*cos(xg),cos(yg).*sin(xg),sin(yg));
zv.addTrimesh('ball/trimesh',reshape(xyz,[],3)',int32(rand(3,10)*numel(xg)));
zv.addMesh('ball/mesh',xyz,zv.applyColormap(@parula,color),0.5 )
zv.addPoints('ball/points',reshape(xyz*1.06,[],3)','r' );
zv.addEdges('ball/edges',reshape([xyz xyz*1.05],[],3)',int32(reshape(1:numel(xg)*2,[],2)'),'g',0.5);
zv.addRectangle('objs/rect',{[0,0,1],[0,0,1]*pi/4,.5},'y');
zv.addMarker('objs/marker',{[0,0,1.5],[0,0,1]*pi/4,.5},'g');
zv.addCamera('objs/camera', [1,0,0], [0,1,0]*pi/2, 0.5, diag([1.5,1,1]), 'r', 1);


% % add points
% zv.addPoints('pcl/xyz',rand(3,1000));
% % add points with intensity
% zv.addPoints('pcl/xyz',rand(4,1000));
% % add points with rgb
% zv.addPoints('pcl/xyzrgb',rand(6,1000));
% % add points with rgba
% zv.addPoints('pcl/xyzrgba',rand(7,1000));
% % add points, force color
% zv.addPoints('pcl/xyzrgba',rand(7,1000),'r');
% % add points, forced color can be rgb
% zv.addPoints('pcl/xyzrgba',rand(7,1000),[1,.2,.3]);
% % forca alpha
% zv.addPoints('pcl/xyzrgba',rand(7,1000),nan,0.5);

