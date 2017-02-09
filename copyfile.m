function [ status, std_out_msg, std_out_id ] = copyfile(varargin)
% copyfile 
%
% Copy a file or directory
%
% Syntax 1:  
% copyfile(<source>, <dest>, <<force-flag>>)
%  
% Syntax 2:
% [ status, std_out_msg, std_out_id ] = copyfile(<source>, <dest>, <<force-flag>>)
%
disp('############### Running copyfile @@@@@@@@@@@@@@');
FORCE_FLAG = false;
status = false;
std_out_msg = '';
std_out_id = 'not used';

if nargin  < 2
  % error('RG: copyfile requires source and destination arguments. \n %s \n', help('copyfile') ); 
  error('RG: copyfile requires source and destination arguments. \n ');
elseif nargin == 3
 force_flag  = varargin{3};
 if force_flag == 'f'
   FORCE_FLAG = true;
 end
elseif nargin > 3
 % error('RG: copyfile() expects a maximum of 3 args. \n %s \n', help('copyfile') );
 error('RG: copyfile() expects a maximum of 3 args. \n ');
end
source = varargin{1};
dest = varargin{2};

% Arguments cannot be the same
if strcmp(source, dest)
  % error ('RG: copyfile() source and dest arguments must be different. \n %s \n', help('copyfile') );
  error ('RG: copyfile() source and dest arguments must be different. \n ');
end

% 
if ~fileattrib(source)
  % error ('RG: copyfile() source does not exist. \n %s \n', help('copyfile') );
  error ('RG: copyfile() source does not exist. \n ');
%end
end

% Entry point logic
if isdir(source) % Assumes recursive dir to dir copy
  source_dir = source;
  % status = copy_dir(dirname, dest, FORCE_FLAG);
  % 
  % If top dest dir exists, deep copy is assumed for top level. Otherwise, 
  % the copy would semantically be a move or overwrite. 
  %
  if fileattrib(dest) && isdir(dest)
    copy_1rst_level_files(source_dir, dest, FORCE_FLAG)  % if top directory exists copy DEEP 
  elseif fileattrib(dest) && ~isdir(dest) % File exists with name specified for dest 
    if FORCE_FLAG == false
      error ('RG: copyfile() cannot copy directory over existing file %s.\nTry using force "-f"\n ' , dest );
    else
      make_dir(dest, true)
      copy_dir(source_dir, dest, FORCE_FLAG);
    end
  else % No file or dir exists with name specified for dest
    make_dir(dest, true)
    copy_dir(source_dir, dest, FORCE_FLAG) 
  end 
elseif fileattrib(dest)
  if isdir(dest) % source is file and dest directory exists (implicitly SHALLOW)
    [pathstr, dest_file, some_ext, versn] = fileparts(source);
    if strcmp(some_ext, '')
       dest_file =  [dest, filesep, dest_file ]; 
    else
       dest_file = [dest, filesep, dest_file,  some_ext ];
    end
    copy_a_file(source, dest_file, FORCE_FLAG);
  else % dest is not dir --file!
    % source is file and no dest dir specified so target is assumed to be a file

    copy_a_file(source, dest, FORCE_FLAG);
  end
else % dest is assumed to be file
  copy_a_file(source, dest, FORCE_FLAG);
 
 
end

status = 1;

function res = copy_a_file( source, dest, FORCE_FLAG );
% Reads source file and writes to dest
%
% Expects source to be a file
% If dest is dir
% - Assumes dest exists or just created
% - Refuses to write to write protected files unless FORCE_FLAG true
% - Copies file to dest_dir/source_file_name
%
% If dest is file 
% - Copies file
% - Forces permissions for file but not directory.
  if FORCE_FLAG
    if fileattrib(dest)
         
       fileattrib(dest, '+w' , 'u')
    
    % Saving this message possibly for later
     else
    error_msg = ['Could not force the write permissions on ', dest ];
    error('%s.\n', error_msg);
    end
 end
 
  dest_file = dest;
    
  res = false;

  try
    F_src = fopen(source, 'r');
  catch io_error
    error(' Caught error while opening source file %s. %s\n', source, io_error.message)
  end

  try
    F_dest = fopen(dest_file, 'w+');
  catch io_error
   error('Caught error while opening file %s\n%s', io_error.message)
  end
 
  try 
  [ A, count_src ] = fread(F_src, Inf, 'int8');
  catch read_error
     error('Caught error while attempting to read %s.\n %s', dest_file, read_error.message)
  end

  try
     [ count_dest ] =  fwrite(F_dest, A, 'int8' );
  catch write_error 
     error('Caught error while attempting to write to %s.\n %s', dest_file, write_error.message);
  end
  fclose(F_src);
  fclose(F_dest);
  res = true;
end

function st_files =  get_file_names( src_dir, st_files )
% Expects an empty struct from caller
% Expects a directory
% Gets files from current directory
  st_files = dir(src_dir);
  st_files = orderfields(st_files);
  % copy hidden but not .. and .
  if strcmp(st_files(1).name, '.') || strcmp(st_files(1).name, '..')
    st_files(1) = []; 
  end
  if strcmp(st_files(1).name, '.') || strcmp(st_files(1).name , '..')
    st_files(1) = [];
  end 
end  

function res = make_dir(dest, FORCE_FLAG)
% - Expects the source to be directory
% - Checks if destination exists 
%   (Creates a new directory if necessary)
% - Returns status to caller
  res =  false;
  if ~fileattrib(dest)  % No existing file or dir with name dest
    try
      mkdir(dest);
      res = true;
    catch io_error
      error('Caught error while creating directory %s \n%s', dest, io_error.message);
    end
  elseif fileattrib(dest) && ~isdir(dest) 
      error('Existing file %s uses same name as destination directory. No copy attempted. You can run with the "force" flag to overwrite this file', dest);
  end
end

function copy_1rst_level_files( source_dir, dest_dir, FORCE_FLAG )
%  1rst step in deep copy to dest_dir.
%  Expects pre-existing destination directory (dest_dir) 
%  - In other words:
%    copyfile Src_name/ Dest_name/ results in Dest_name/Src_name/ 
% - Copy files from a source directory to an existing dest directory (dest_dir)
% - Expects a directory exists for both source and dest_dir.
% - calls copy_files
% 
 source_dir
 D = get_file_names(source_dir , struct([]));
 
  for i = 1 : size(D)

    if D(i).isdir
        source_dir_path = [ source_dir, filesep, D(i).name ]
        next_dest_dir = [ dest_dir, filesep, source_dir, filesep, D(i).name] 
        if fileattrib(next_dest_dir) % dest dir already exists
          copy_files(source_dir, next_dest_dir, FORCE_FLAG );
        else 
          make_dir(next_dest_dir);
          copy_files(source_dir, next_dest_dir, FORCE_FLAG);
        end
    else % D(i) is not a dir
      source_file_path    = [ source_dir, filesep, D(i).name ];
      dest_file_path = [ dest_dir, filesep, source_dir, filesep, D(i).name ];
      if fileattrib(dest_file_path) % file already exists
         if FORCE_FLAG 
           fileattrib(dest_file_path, '+w' , 'u');
         end
         copy_a_file(source_file_path, dest_file_path, FORCE_FLAG);
      else
        make_dir( [ dest_dir, filesep, source_dir ] );
        copy_a_file(source_file_path, dest_file_path, FORCE_FLAG);
      end
    end
  end
end

function copy_files( source_dir, dest_dir, FORCE_FLAG )
% - Copy files from a directory to a directory (dest_dir)
% - Expects a directory.
% Calls copy_file for each file in the directory
% 
 D = get_file_names(source_dir , struct([]));

  for i = 1 : size(D)

    if D(i).isdir
        source_dir = [ source_dir, filesep, D(i).name ] ;
        next_dest_dir = [ dest_dir, filesep, D(i).name] ;
        if fileattrib(next_dest_dir) % already exists
          copy_files(source_dir, next_dest_dir, FORCE_FLAG );
        else
          make_dir(next_dest_dir);
          copy_files(source_dir, next_dest_dir, FORCE_FLAG);
        end
    else % D(i) is not a dir
      source_file_path    = [ source_dir, filesep, D(i).name ];
      dest_file_path = [ dest_dir, filesep, D(i).name ];
      if  fileattrib(dest_file_path) % file already exists
         if FORCE_FLAG
           fileattrib(dest_file_path, '+w' , 'u');
         end
         copy_a_file(source_file_path, dest_file_path, FORCE_FLAG);
      else
        copy_a_file(source_file_path, dest_file_path, FORCE_FLAG);
      end
    end
  end
end

function copy_dir( source_dir, dest_dir, FORCE_FLAG )
% - Copy files from a directory to a new directory (dest_dir)
% - Expects a directory.
% Calls copy_file for each file in the directory
% 
  D = get_file_names(source_dir , struct([]));
  
  for i = 1 : size(D)

    if D(i).isdir
        next_dest_dir = [ dest_dir, filesep, D(i).name];
        next_source_dir = [ source_dir , filesep, D(i).name ];
        make_dir( next_dest_dir )
        copy_dir(next_source_dir, next_dest_dir, FORCE_FLAG);
    else % not a dir
        source_file_path =  [ source_dir, filesep, D(i).name ];
        dest_file_path =  [ dest_dir , filesep, D(i).name ];
        copy_a_file(source_file_path, dest_file_path, FORCE_FLAG);
    end
  end
end

end 
