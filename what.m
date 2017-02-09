function y  = what(varargin)
% what List Star-P Specific files in directory
%
% Syntax 1:
% what <directory-name>   % Prints Star-P M# files in the working directory
%
% Syntax 2:
% <<dir-info-struct>> = what( <directory-name> )

if nargin  < 1
  x = '.';
elseif nargin == 1
  x = varargin{1};   
else 
  error('1 input argument only');
end

if ~exist(x)
  warning('The path or file name "%s" is not valid', x);
  return
end

% Check if full path
if isdir(x) && (filesep == x(1))
  path_to_dir_class_or_folder = x;
else
  [stat, message, id]  = fileattrib(x);
  path_to_dir_class_or_folder = message.Name;
  % Workaround for fileattrib s.Name - ticket 95118
  path_to_dir_class_or_folder = char(path_to_dir_class_or_folder); 
end

st_what.path = path_to_dir_class_or_folder;
st_what.m = { };
st_what.mat = { };
st_what.mex = { };
st_what.mdl = { };
st_what.p = { };
st_what.classes = { };
st_what.packages = { };

st_not_used.dirs = { };
st_not_used.built_ins = { };

if nargout == 1
 % surpress display
 MYDISPLAY = false;
elseif nargout < 1
 % pretty print flag 
 MYDISPLAY = true;
else
 error('max 1 out argument only');
 return
end

function [res] = validate_m_specific_file(pathname)
  exist_category = exist(pathname);
  [pathstr, name, ext, versn] = fileparts(pathname);
  res = true;
  % fprintf('%f   %s  %s \n' , exist_category , name, ext );
  switch exist_category 
    case 0
      warning('File does not exist');
      pathname;
      res = false;
    case 2
      % M file
      % Checks if real file and then check extension for M-ness
      if strcmp(ext, '.m')
        st_what.m(end + 1,1) =  { [name , ext] };
      else 
        res = false;
      end
    case 3
      % Mex file
      st_what.mex(end + 1,1) = { [name , ext] }; 
    case 4
      % Mdl file
      st_what.mdl(end + 1,1) = { [name , ext] }; 
    case 5
      % built in
      st_not_used.built_ins(end + 1,1) = { [name , ext] }; 
    case 7
      % Directories are ignored by what
      st_not_used.dirs(end + 1, 1) = { [ name ] }; 
      res = false;
    otherwise 
      res = false;
    end 
end

function [res] = disp_fields( st_what)
  [res1 , res2 , res3 , res4 , res5 , res6 , res7]  = deal('');

  if ~(isequal(st_what.m, {} ) )
    res1 = sprintf('\nM-files in directory %s\n\n', path_to_dir_class_or_folder);
    res1 = [res1, sprintf('%s\t', st_what.m{:})];
  end

  if ~(isequal(st_what.mat, {}) )
    res2 = sprintf('\n\nMAT files in directory %s\n\n', path_to_dir_class_or_folder);
    res2 = [res2, sprintf('%s\t', st_what.mat{:})];
  end

  if ~(isequal(st_what.mex, {}) )
    res3 = sprintf('\n\nMEX files in directory %s\n\n', path_to_dir_class_or_folder);
    res3 = [res3, sprintf('%s\t', st_what.mex{:})];
  end

  if ~(isequal(st_what.mdl, {}) )
    res4 = sprintf('\n\nMDL files in directory %s\n\n', path_to_dir_class_or_folder);
    res4 = [res4, sprintf('%s\t', st_what.mdl{:})];
  end

  if ~(isequal(st_what.p, {}) )
    res5 = sprintf('\n\nP files in directory %s\n\n', path_to_dir_class_or_folder);
    res5 = [res5, sprintf('%s\t', st_what.p{:})];
  end

  if ~(isequal(st_what.classes, {}) )
    res6 = sprintf('\n\nClass files in directory %s\n\n', path_to_dir_class_or_folder);
    res6 = [res6, sprintf('%s\t', st_what.classes{:})];
  end

  if ~(isequal(st_what.packages, {}) )
    res7 = sprintf('\n\nClass files in directory %s\n\n', path_to_dir_class_or_folder);
    res7 = [res6, sprintf('%s\t', st_what.packages{:})];
  end

  o_put = [ res1, res2, res3, res4, res5, res6, res7 ];
  if ~strcmp(o_put, '')
      disp(o_put);
      res = true;
  else
  res = false; 
  end
end

function [current_name] = fix_filesep( current_path , filename )

  if current_path(end) == filesep
     current_name = [ current_path , filename ];
  else
     current_name = [ current_path ,filesep, filename ];
  end
end

path_to_dir_class_or_folder = char(path_to_dir_class_or_folder);
st_dir_contents = dir(path_to_dir_class_or_folder);
match = false;
[max_i,max_j] = size(st_dir_contents);
 for i = 1:max_i
    current_name = fix_filesep(path_to_dir_class_or_folder, st_dir_contents(i).name);
    if (validate_m_specific_file(current_name));
       match = true;
    end
  end % End for %

% no matches 
% surpress pretty print
% if MYDISPLAY && ~match
% do nothing
if MYDISPLAY
  disp_fields(st_what);
  % do nothing 
else 
  y = st_what;
end

end % end file %
