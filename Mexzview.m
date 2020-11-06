classdef Mexzview < handle
    %MEXZVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        handle
        objects
    end
    
    methods (Access=private)
        function tri=getTrimeshIndices(~,sz)
            indx = reshape(0:sz(1)*sz(2)-1,sz(1:2));
            p1=indx(1:end-1,1:end-1);
            p2=indx(1:end-1,2:end);
            p3=indx(2:end,1:end-1);
            p4=indx(2:end,2:end);
            tri_a = reshape(cat(3,p4,p1,p2),[],3);
            tri_b = reshape(cat(3,p4,p3,p1),[],3);
            tri = reshape([tri_a tri_b]',3,[]);
            
            tri = int32(tri);
            
        end
        
        function col=str2rgb(~,colorstr)
            switch(colorstr)
                case 'r',    col = [1, 0, 0];
                case 'g',    col = [0, 1, 0];
                case 'b',    col = [0, 0, 1];
                case 'c',    col = [0, 1, 1];
                case 'm',    col = [1, 0, 1];
                case 'y',    col = [1, 1, 0];
                case 'w',    col = [1, 1, 1];
                case 'k',    col = [0, 0, 0];
                case 'R', col = rand(1,3);
            end
        end
        
        function tform = getTform(obj, tform_or_trs)
            
            if ismatrix(tform_or_trs) && all(size(tform_or_trs)==[4,4])
                tform = tform_or_trs;
            elseif ismatrix(tform_or_trs) && all(size(tform_or_trs)==[3,4])
                tform = eye(4);
                tform(1:3, :) = tform_or_trs;
            elseif iscell(tform_or_trs)
                [t, r, s] = tform_or_trs{:};
                
                tform = eye(4);
                if isnan(r)
                elseif all(size(r)==[3,3])
                    tform(1:3,1:3) = r;
                elseif numel(r)==3
                    tform(1:3,1:3) = obj.rotationMatrix(r);
                else
                    error("unknown rotation strucutre")
                end
                sv = eye(4);
                if isnan(s)
                    
                elseif length(s)==1
                    sv(1:3,1:3)=sv(1:3,1:3)*s;
                elseif length(s)==3
                    sv(1:3,1:3)=diag(s);
                else
                    error("unknown scale structure")
                end
                tform = tform * sv;
                if isnan(t)
                elseif length(t)==3
                    tform(1:3,4)=t;
                else
                    error("unknown translation structure")
                end
            else
                error("unknown transforation structure")
            end
        end
        
        
        function namehandle=set_obj(obj, objtype, namehandle, tform_or_trs, color, alpha)
            
            tform = obj.getTform(tform_or_trs);
            obj_cell= obj.objects(objtype);
            xyz = tform(1:3, 1:3)*obj_cell{1}  + tform(1:3,4);
            namehandle= obj.addTrimesh(namehandle,xyz,obj_cell{2},color,alpha);
        end
        function r=rotationMatrix(~,rot_vec)
            angle = norm(rot_vec);
            if angle == 0
                r=eye(3);
            else
                v = rot_vec(:) / angle;
                c = [0, -v(3), v(2);v(3), 0, -v(1);-v(2), v(1), 0];
                r = eye(3) + c * sin(angle) + (1 - cos(angle)) * c * c;
            end
        end
        
        
        
        function xyzf=getPtsArr(obj,xyz, color, alpha)
            xyz = single(xyz);
            if length(size(xyz))==3
                xyz = reshape(xyz,size(xyz,1),[]);
            end
            if length(size(xyz)) == 2 && size(xyz,1)==1
                xyz = xyz.';
            end
            [ch, n] = size(xyz);
            switch(ch)
                case 3,xyzrgba =[xyz;ones(4,n)];
                case 4,xyzrgba =[xyz;xyz(4,:).*ones(2,1);ones(1,n)];
                case 6,xyzrgba =[xyz;ones(1,n)];
                case 7,xyzrgba =xyz;
                otherwise, error('unknown number of channels');
            end
            
            if ~isnan(alpha)
                xyzrgba(7,:) = alpha;
            end
            if ~isnan(color)
                if isa(color, 'char')
                    xyzrgba(4:6,:) = (obj.str2rgb(color))'*ones(1,n);
                elseif isnumeric(color)
                    if length(color)==3
                        xyzrgba(4:6,:) = color(:)*ones(1,n);
                    elseif length(color)==n
                        xyzrgba(4:6,:) = color(:)'.*ones(3,1);
                    elseif numel(color)/n==3
                        xyzrgba(4:6,:) = reshape(color,[],3)';
                    elseif numel(color)/n==4
                        xyzrgba(4:7,:) = reshape(color,[],4)';
                    else
                        error("unknown color size");
                    end
                else
                    error("unknown color type");
                end
                
            end
            
            rgba = xyzrgba(4:7,:);
            rgba =max(0,min(1,rgba));
            rgba = typecast(uint8(rgba(:) *255),'single')';
            xyzf=[xyzrgba(1:3,:);rgba];
        end
        
    end
    
    methods
        function delete(obj)
            zview_module('delete',obj.handle);
        end
        
        function obj = Mexzview()
            
            s = 1 / sqrt(3);
            obj.objects = containers.Map;
            obj.objects('marker') = {[-1, -s, 0;0, 2 * s, 0;1, -s, 0;0, 0, sqrt(8) * s]' / 2,[0, 3, 1;1, 3, 2;0, 2, 3;0, 2, 1]'};
            obj.objects('rect') = {[0, 0, 0;0, 1, 0;1, 1, 0;1, 0, 0;0, 0, 1;0, 1, 1;1, 1, 1;1, 0, 1]'* 2 - 1,...
                [3, 1, 0;3, 1, 2;3, 6, 2;3, 7, 6;0, 1, 5;0, 5, 4;0, 7, 4;0, 3, 7;1, 2, 6;1, 6, 5;5, 6, 7;4, 5, 7]'};
            obj.objects('camera') = {[0, 0, 0;1, 1, 1;-1, 1, 1;-1, -1, 1;1, -1, 1;1, 0, 0;1, 0.1, 0;0, 1, 0;0.1, 1, 0]',...
                [0, 1, 2;0, 2, 3;0, 3, 4;0, 4, 1;1, 2, 3;1, 3, 4;0, 6, 5;0, 7, 8]'};
            for x=obj.objects.keys
                cell_data=obj.objects(x{1});
                cell_data{1}=single(cell_data{1});
                cell_data{2}=int32(cell_data{2});
                obj.objects(x{1})=cell_data;
            end
            
            obj.handle= zview_module('new');
        end
        
        function removeShape(obj, namehandle)
            if ~exist('namehandle','var')
                namehandle=int64(-1);
            end
            if isa(namehandle,'char')
                namehandle = zview_module('getHandleNumFromString',obj.handle,namehandle);
            end
            zview_module('removeShape',obj.handle,namehandle);
        end
        
        
        function handlenum =  addEdges(obj, namehandle, xyz, edgepair, color, alpha)
            
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            if length(size(xyz)) ~= 2
                error("expecting nxD for D>=3")
            end
            xyzf = obj.getPtsArr(xyz, color, alpha);
            if isa(namehandle,'char')
                handlenum = zview_module('getHandleNumFromString',obj.handle,namehandle);
                if handlenum == -1
                    
                    handlenum = zview_module('addColoredEdges',obj.handle,namehandle, xyzf, edgepair);
                else
                    ok = zview_module('updateColoredPoints',obj.handle,handlenum, xyzf);
                    if ~ok
                        %#visualization data is stored in a vertex buffer. If you are tryig to update an array which is bigger than the vertex buffer, than we have a problem...
                        error('could not update points with the different size. create a new set for new point size');
                    end
                end
            elseif(isa(namehandle,'int64'))
                zview_module('updateColoredPoints',obj.handle,namehandle, xyzf);
            else
                error('Bad handlenum argument')
            end
        end
        function handlenum = addPoints(obj, namehandle, xyz, color, alpha)
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
            
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            
            xyzf = obj.getPtsArr(xyz, color, alpha);
            if isa(namehandle,'char')
                handlenum = zview_module('getHandleNumFromString',obj.handle,namehandle);
                if handlenum == -1
                    handlenum = zview_module('addColoredPoints',obj.handle,namehandle, xyzf);
                else
                    ok = zview_module('updateColoredPoints',obj.handle,handlenum, xyzf);
                    if ~ok
                        %#visualization data is stored in a vertex buffer. If you are tryig to update an array which is bigger than the vertex buffer, than we have a problem...
                        error('could not update points with the different size. create a new set for new point size');
                    end
                end
                
            elseif(isa(namehandle,'int64'))
                zview_module('updateColoredPoints',obj.handle,namehandle, xyzf);
            else
                error('Bad handlenum argument')
            end
        end
        
        function handlenum =  addTrimesh(obj, namehandle, xyz, faces, color, alpha)
            
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            if length(size(xyz)) ~= 2
                error("expecting nxD for D>=3")
            end
            xyzf = obj.getPtsArr(xyz, color, alpha);
            if isa(namehandle,'char')
                handlenum = zview_module('getHandleNumFromString',obj.handle,namehandle);
                if handlenum == -1
                    
                    handlenum = zview_module('addColoredMesh',obj.handle,namehandle, xyzf, faces);
                else
                    ok = zview_module('updateColoredPoints',obj.handle,handlenum, xyzf);
                    if ~ok
                        %#visualization data is stored in a vertex buffer. If you are tryig to update an array which is bigger than the vertex buffer, than we have a problem...
                        error('could not update points with the different size. create a new set for new point size');
                    end
                end
            elseif(isa(namehandle,'int64'))
                zview_module('updateColoredPoints',obj.handle,namehandle, xyzf);
            else
                error('Bad handlenum argument')
            end
        end
        
        function handlenum = addMesh(obj, namehandle, xyz, color, alpha)
            %             [yg,xg] = ndgrid(linspace(-1,1,64)*pi/2,linspace(-1,1,64)*pi);
            % color=abs(sin(4*yg).*sin(4*xg).*sin(4*yg));
            % zv.addMesh('mesh/xyz',cat(3,cos(yg).*cos(xg),cos(yg).*sin(xg),sin(yg),zv.applyColormap(@parula,color) ))
            
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            if length(size(xyz)) ~= 3
                error("expecting nxmxD for D>=3")
            end
            xyzf = obj.getPtsArr(reshape(xyz,[],size(xyz,3))', color, alpha);
            if isa(namehandle,'char')
                handlenum = zview_module('getHandleNumFromString',obj.handle,namehandle);
                if handlenum == -1
                    faces = obj.getTrimeshIndices(size(xyz));
                    handlenum = zview_module('addColoredMesh',obj.handle,namehandle, xyzf, faces);
                else
                    ok = zview_module('updateColoredPoints',obj.handle,handlenum, xyzf);
                    if ~ok
                        %#visualization data is stored in a vertex buffer. If you are tryig to update an array which is bigger than the vertex buffer, than we have a problem...
                        error('could not update points with the different size. create a new set for new point size');
                    end
                end
            elseif(isa(namehandle,'int64'))
                zview_module('updateColoredPoints',obj.handle,namehandle, xyzf);
            else
                error('Bad handlenum argument')
            end
        end
        
        function vrgb = applyColormap(~,cm_func,v)
            if isa(cm_func,'function_handle')
                map=cm_func(256);
            elseif is(cm_func,'char')
                map=eval(sprintf('%s(256)',cm));
            elseif isnumeric(cm_func) && size(cm_func,2)==3
                map=cm_func;
            else
                error('unknonwn colormap options');
            end
            v = v-min(v(:));
            v = uint32(v/max(v(:))*(size(map,1)-1))+1;
            map=permute(map,[1 3 2]);
            vrgb=reshape(map(v(:),:),[size(v) 3]);
            
        end
        function key=getLastKeyStroke(obj)
            key = zview_module('getLastKeyStroke',obj.handle);
        end
        
        function handlenum = addRectangle(obj, name, tform_or_trs, color, alpha)
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            handlenum = obj.set_obj('rect', name, tform_or_trs, color, alpha);
        end
        
        
        function handlenum =  addCamera(obj, namehandle, t, r, scale, k, color, alpha)
            if(~exist('alpha','var'))
                alpha=1;
            end
            if(~exist('color','var'))
                color=[1,1,1];
            end
            if(~exist('scale','var'))
                scale=1;
            end
            if(~exist('k','var'))
                k=eye(3);
            end
            
            tform = obj.getTform({t, r, nan});
            cam_data =obj.objects('camera');
            v = cam_data {1} * scale;
            v(:,1:5) = k\v(:,1:5);
            v = tform(1:3,1:3)*v  + tform(1:3, 4);
            rgba = [obj.str2rgb(color) alpha]'*ones(1,size(v,2));
            rgba(1:3,1)=[1,1,1];
            rgba(1:3,6:7)=[1;0;0]*[1 1];
            rgba(1:3,8:9)=[0;1;0]*[1 1];
            handlenum = obj.addTrimesh(namehandle,[v;rgba],cam_data{2});
        end
        
            function handlenum = addMarker(obj, name, tform_or_trs, color, alpha)
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            handlenum = obj.set_obj('marker', name, tform_or_trs, color, alpha);
        end
        
        
        
    end
end
