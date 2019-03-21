classdef intlab < handle
  % SDPT3  Solver proxy class (not the acutal solver!).
  %
  % For information about SDPT3, see:
  %
  %      http://www.math.nus.edu.sg/~mattohkc/sdpt3.html
  %      https://github.com/sqlp/sdpt3
  %
  %   See also vsdp.solve.
  %
  
  methods (Static)
    function obj = solve (obj, sol_type)
      % SOLVE  Approximately solve conic problem instance with SDPT3.
      %
      %   See also vsdp.solve.
      %
      
      % Copyright 2004-2018 Christian Jansson (jansson@tuhh.de)
      
      narginchk (1, 2);
      
      solver.sdpt3.install ();
      
      if (nargin == 1)
        sol_type = 'Approximate';
      end
      [A, b, c] = obj.get_midpoint_problem_data (sol_type);
      
      % Should initial solution guess be taken into account?
      if ((obj.options.USE_INITIAL_GUESS) ...
          && (~isempty (obj.solution('Initial'))))
        isol = obj.solution('Initial');
        [x0, y0, z0] = deal (isol.x, isol.y, isol.z);
      else
        [x0, y0, z0] = deal ([], [], []);
      end
      
      % Should special solver options be taken into account?
      if (~isempty (obj.options.SOLVER_OPTIONS))
        OPTIONS = obj.options.SOLVER_OPTIONS;
      else
        OPTIONS = [];
      end
      
      % Adapt output verbosity.
      if (~obj.options.VERBOSE_OUTPUT)
        if (exist ('sqlpmain.m', 'file') == 2) % if SDPT3-4.0
          OPTIONS.printlevel = 0; % default: 3
        else
          OPTIONS.printyes = 0;   % default: 1
        end
      end
      
      % Prepare data for solver.
      A = vsdp.smat (obj, A, 1);
      c = vsdp.smat (obj, c, 1);
      [blk, A, c, b] = read_sedumi (A, b, c, obj.K);
      
      % Call solver.
      tic;
      [~, x, y, z, info] = sqlp (blk, A, c, b, OPTIONS, x0, y0, z0);
      solver_info.elapsed_time = toc;
      
      % Store solution.
      x = vsdp.svec (obj, vsdp.cell_sub_blocks (x(:), blk), 2);
      z = vsdp.svec (obj, vsdp.cell_sub_blocks (z(:), blk), 1);
      f_objective = [obj.c'*x; obj.b'*y];
      solver_info.name = 'sdpt3';
      if (isstruct (info))
        termcode = info.termcode;  % SDPT3-4.0 output
      else
        termcode = info(1);  % SDPT3-3.x output
      end
      switch (termcode)
        case 0
          solver_info.termination = 'Normal termination';
        case 1
          solver_info.termination = 'Primal infeasible';
        case 2
          solver_info.termination = 'Dual infeasible';
        otherwise
          solver_info.termination = 'Unknown';
      end
      
      obj.add_solution (sol_type, x, y, z, f_objective, solver_info);
    end
    
    function [f,l,q,s] = supported_cones ()
      f = true;  % free   variables.
      l = true;  % linear variables.
      q = true;  % second-order cones.
      s = true;  % semidefinite cones.
    end
    
    function solver_path = install ()
      % Returns the path to the solver directory, if useable.  Otherwise return
      % empty value.
      %
      
      solver_path = vsdp.settings ('sdpt3', 'path');
      is_available = @() exist ('sqlp', 'file') == 2;
      
      if (is_available ())
        if (isempty (solver_path))  % Store solver path persistent.
          solver_path = vsdp.settings ('sdpt3', 'path', ...
            fileparts (which ('install_sdpt3')));
        end
        return;  % Nothing else to do.
      end
      
      % Recovery 1: Check if VSDP knows a setup location.
      if (~isempty (solver_path))
        installer_file = fullfile (solver_path, 'install_sdpt3.m');
        if (exist (installer_file, 'file') == 2)
          run (installer_file);
          % Final check.
          if (exist ('sqlp', 'file') ~= 2)
            solver_path = [];
          end
        else
          solver_path = [];
        end
      end
      
      % Recovery 2: Install solver from the internet.
      urlwrite ('https://github.com/sqlp/sdpt3/archive/master.zip', ...
        fullfile (vsdp.settings ('vsdp', 'path')))
      if (~isempty (solver_path))
        installer_file = fullfile (solver_path, 'install_sdpt3.m');
        if (exist (installer_file, 'file') == 2)
          run (installer_file);
          % Final check.
          if (exist ('sqlp', 'file') ~= 2)
            solver_path = [];
          end
        else
          solver_path = [];
        end
      end
    end
  end
end
