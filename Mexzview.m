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
            
            tri_a = reshape(cat(3,indx(1:end-1,2:end),indx(1:end-1,1:end-1),indx(2:end,2:end)),[],3);
            tri_b = reshape(cat(3,indx(1:end-1,1:end-1),indx(2:end,1:end-1),indx(2:end,2:end)),[],3);
            tri = [tri_a;tri_b];
            tri = int32(tri)';
            
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
        
        function xyzf=get_pts_arr(obj,xyz, color, alpha)
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
            obj.handle= zview_module('new');
            s = 1 / sqrt(3);
            objects = containers.Map;
            objects('marker') = {[-1, -s, 0;0, 2 * s, 0;1, -s, 0;0, 0, sqrt(8) * s] / 2,[0, 3, 1;1, 3, 2;0, 2, 3;0, 2, 1]};
            objects('rect') = {[0, 0, 0;0, 1, 0;1, 1, 0;1, 0, 0;0, 0, 1;0, 1, 1;1, 1, 1;1, 0, 1]* 2 - 1,...
                [3, 1, 0;3, 1, 2;3, 6, 2;3, 7, 6;0, 1, 5;0, 5, 4;0, 7, 4;0, 3, 7;1, 2, 6;1, 6, 5;5, 6, 7;4, 5, 7]};
            objects('camera') = {[0, 0, 0;1, 1, 1;-1, 1, 1;-1, -1, 1;1, -1, 1;1, 0, 0;1, 0.1, 0;0, 1, 0;0.1, 1, 0],...
                [0, 1, 2;0, 2, 3;0, 3, 4;0, 4, 1;1, 2, 3;1, 3, 4;0, 6, 5;0, 7, 8]};
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
        
        function handlenum = addPoints(obj, namehandle, xyz, color, alpha)
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            
            xyzf = obj.get_pts_arr(xyz, color, alpha);
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
        
        function handlenum = addMesh(obj, namehandle, xyz, color, alpha)
            if(~exist('alpha','var'))
                alpha=nan;
            end
            if(~exist('color','var'))
                color=nan;
            end
            if length(size(xyz)) ~= 3
                error("expecting nxmxD for D>=3")
            end
            xyzf = obj.get_pts_arr(reshape(xyz,[],size(xyz,3))', color, alpha);
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
    end
end
