classdef registry < handle
  methods (Static)
    function slist = list_all ()
      % LIST_ALL  Return a list with all solvers supported by VSDP.
      %
      %    Return a cell array of strings with solvers supported by VSDP.
      %
      %       slist = solver.registry.list_all ()
      %
      
      % Change to VSDP root directory.
      old_dir = cd (vsdp.settings ('vsdp', 'path'));
      
      % Generate a list of supported solvers.
      slist = dir ('+solver');
      cd (old_dir);
      
      slist = {slist.name};
      idx = (cellfun (@length, slist) > 2);      % Strip items like '.' and '..'.
      idx = idx & ~strcmp ('registry.m', slist); % Strip this function.
      slist = slist(idx);
      % Strip *.m suffix.
      [~, slist] = cellfun (@fileparts, slist, 'UniformOutput', false);
      slist = slist(:);
    end
    
    function slist = list_available ()
      % LIST_AVAILABLE  Return a list with all available solvers.
      %
      %    Return a cell array of strings with all available solvers.
      %
      %       slist = solver.registry.list_available ()
      %
      
      slist = solver.registry.install_all (true);
      slist = {slist.name}';
      slist = slist(~strcmp ('intlab', slist)); % INTLAB is no available solver.
    end
    
    function spath = generic_install (sname, is_available, get_path, ...
        installer_file, do_error)
      % GENERIC_INSTALL  Perform a generic solver installation.
      %
      %    spath = generic_install (sname, is_available, get_path, do_error)
      %
      %    spath          - (char) detected solver path
      %    sname          - (char) solver name
      %    is_availalbe   - (function handle) Determine solver availability.
      %    get_path       - (function handle) Determine solver path.
      %    installer_file - (char) Name of the solver installation function
      %                     or script.
      %    do_error       - (logical scalar)  Should this function throw errors,
      %                     if the generic installation fails?
      %
      
      spath = vsdp.settings (sname, 'path');
      
      if (is_available ())
        if (isempty (spath))  % Store solver path persistent.
          spath = vsdp.settings (sname, 'path', get_path ());
        end
        return;  % Nothing else to do.
      end
      
      % Check if VSDP knows an existing setup location.
      if (~isempty (spath))
        if (exist (spath, 'dir') == 7)
          addpath (spath);
          installer_file = fullfile (spath, installer_file);
          if (exist (installer_file, 'file') == 2)
            run (installer_file);
          end
          if (is_available ())  % Final check.
            return;
          else
            rmpath (spath);  % Gives up here, delete useless path.
            spath = vsdp.settings (sname, 'path', []);
          end
        else
          % Gives up here, delete useless path.
          spath = vsdp.settings (sname, 'path', []);
        end
      end
      
      if (do_error)
        error ('VSDP:SOLVER:REGISTRY:generic_install:failed', ...
          'solver.registry.generic_install: ''%s'' is not available.', sname);
      end
    end
    
    
    function slist = install_all (remove_unavailable_solver)
      % INSTALL_ALL  Return a list with all available solvers.
      %
      %    Return a list of available solver and their installation path.
      %
      %       slist = solver.registry.install_all ()
      %
      
      slist = solver.registry.list_all ();
      plist = cell (size (slist));
      for i = 1:length (slist)
        plist{i} = eval (sprintf ('solver.%s.install ();', slist{i}));
      end
      idx = true (size (slist));
      if ((nargin == 1) && logical (remove_unavailable_solver))
        idx = ~cellfun (@isempty, plist);
      end
      slist = cell2struct ([slist(idx), plist(idx)]', {'name', 'path'});
    end
    
    function str = status ()
      slist = solver.registry.install_all ();
      plist = {slist.path};
      slist = {slist.name};
      idx = cellfun (@isempty, plist);
      plist(idx) = {'-- not available --'};
      output = [slist; plist];
      str = sprintf ('    %-10s (%s)\n', output{:});
      str = sprintf ('\n  Solver detected by VSDP:\n\n%s', str);
      if (nargout == 0)
        disp (str);
        str = [];
      end
      
    end
  end
end