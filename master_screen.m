function master_screen()
    %% (Optional) Reset persistent data for a new game
    if isfile('car_stats.mat')
        delete('car_stats.mat');
    end
    if isfile('race_data.mat')
        delete('race_data.mat');
    end

    %% Create Main Figure and Custom Background for the entire figure
    f = figure('Name', 'F1 Master Screen', 'NumberTitle', 'off',...
        'Units','normalized','Position',[0.1,0.1,0.8,0.8],'Color',[0.1,0.1,0.1]);
    datacursormode(f, 'off'); % Disable interactive data tips

    % Set up appdata for real-time performance data.
    setappdata(f, 'rtLapTimes', []);
    setappdata(f, 'rtBrakeZones', []);
    setappdata(f, 'rtTireWear', []);
    setappdata(f, 'rtERS', []);
    % Also set up storage for base speed data per lap.
    setappdata(f, 'rtBaseSpeed', []);
    % Clear any final upgrade snapshot.
    setappdata(f, 'finalUpgrade', []);
    % Set initial speed multiplier (1 = normal, 2 = 2x speed)
    setappdata(f, 'speedMultiplier', 1);

    % Generate a dark vertical gradient background.
    bgAxes = axes('Parent', f, 'Units', 'normalized','Position',[0,0,1,1]);
    [x, y] = meshgrid(linspace(0,1,800), linspace(0,1,600));
    bgImage = repmat(y, [1, 1, 3]);
    bgImage = 0.1 + 0.1 * bgImage;
    imshow(bgImage, 'Parent', bgAxes);
    hold(bgAxes, 'on');
    for k = 0:0.05:1
        plot(bgAxes, [0 1], [k k], 'Color', [0.15,0.15,0.15], 'LineStyle', '--','LineWidth',1.5);
        plot(bgAxes, [k k], [0 1], 'Color', [0.15,0.15,0.15], 'LineStyle', '--','LineWidth',1.5);
    end
    hold(bgAxes, 'off');
    uistack(bgAxes, 'bottom');

    %% Create Main Panels
    % Left Panel (Main Menu) – occupies 30% width. (Dark red/brick-orange for retro LEGO)
    leftPanel = uipanel('Parent', f, 'Units', 'normalized',...
        'Position',[0,0,0.3,1], 'BackgroundColor',[1,0.8,0]);
    % Right Panel (Content Area) – occupies 70% width. (Retro blue)
    rightPanel = uipanel('Parent', f, 'Units', 'normalized',...
        'Position',[0.3,0,0.7,1], 'BackgroundColor',[0,0.3,0.6]);

    % Create 4 subpanels (2×2 grid) inside the right panel.
    simPanel = uipanel('Parent', rightPanel, 'Units', 'normalized',...
        'Position',[0.05,0.55,0.4,0.4], 'BackgroundColor',[0,0,0.5]);
    analyzePanel = uipanel('Parent', rightPanel, 'Units', 'normalized',...
        'Position',[0.55,0.55,0.4,0.4], 'BackgroundColor',[0,0,0.5]);
    performancePanel = uipanel('Parent', rightPanel, 'Units', 'normalized',...
        'Position',[0.05,0.05,0.4,0.4], 'BackgroundColor',[0,0,0.5]);
    upgradePanel = uipanel('Parent', rightPanel, 'Units', 'normalized',...
        'Position',[0.55,0.05,0.4,0.4], 'BackgroundColor',[0,0,0.5]);

    %% Left Panel Menu (Vertically Centered)
    delete(allchild(leftPanel));
    uicontrol('Parent', leftPanel, 'Style', 'text', 'String', 'Main Menu',...
        'Units', 'normalized', 'Position', [0.1,0.85,0.8,0.1], 'FontSize', 18,...
        'FontWeight', 'bold', 'ForegroundColor', [1,1,1], 'BackgroundColor', [1,0.8,0],...
        'HorizontalAlignment', 'center');
    % Create buttons: "Simulate Race", "Save and Exit", and "Show Raw Data"
    buttonHeight = 0.1; spacing = 0.02; 
    blockHeight = 3 * buttonHeight + 2 * spacing; % now three buttons
    startY = 0.5 + blockHeight/2 - buttonHeight;
    uicontrol('Parent', leftPanel, 'Style', 'pushbutton', 'String', 'Simulate Race',...
        'Units', 'normalized', 'Position', [0.1, startY, 0.8, buttonHeight],...
        'FontSize', 14, 'FontWeight', 'bold', 'ForegroundColor', [1,1,1],...
        'BackgroundColor', [1,0.8,0], 'Callback', @launchSimulation);
    uicontrol('Parent', leftPanel, 'Style', 'pushbutton', 'String', 'Save and Exit',...
        'Units', 'normalized', 'Position', [0.1, startY - buttonHeight - spacing, 0.8, buttonHeight],...
        'FontSize', 14, 'FontWeight', 'bold', 'ForegroundColor', [1,1,1],...
        'BackgroundColor', [1,0.8,0], 'Callback', @(src,event) close(f));
    uicontrol('Parent', leftPanel, 'Style', 'pushbutton', 'String', 'Show Raw Data',...
        'Units', 'normalized', 'Position', [0.1, startY - 2*(buttonHeight + spacing), 0.8, buttonHeight],...
        'FontSize', 14, 'FontWeight', 'bold', 'ForegroundColor', [1,1,1],...
        'BackgroundColor', [1,0.8,0], 'Callback', @showRawData);

    %% Initial Right Panel Content
    delete(allchild(analyzePanel));
    uicontrol('Parent', analyzePanel, 'Style', 'text', 'String', ...
        'No race data available.\nPlease simulate a race first.', ...
        'Units', 'normalized', 'Position', [0.1,0.3,0.8,0.4], 'FontSize', 14, ...
        'ForegroundColor', [1,1,1], 'BackgroundColor', [0,0,0.5],...
        'HorizontalAlignment', 'center');
    delete(allchild(performancePanel));
    uicontrol('Parent', performancePanel, 'Style', 'text', 'String', ...
        'No race data available.\nPlease simulate a race first.', ...
        'Units', 'normalized', 'Position', [0.1,0.3,0.8,0.4], 'FontSize', 14, ...
        'ForegroundColor', [1,1,1], 'BackgroundColor', [0,0,0.5],...
        'HorizontalAlignment', 'center');
    populateUpgrade();  % Show initial persistent upgrade tally.
    delete(allchild(simPanel));
    uicontrol('Parent', simPanel, 'Style', 'text', 'String', ...
        'Press "Simulate Race" to run a race.', ...
        'Units', 'normalized', 'Position', [0.1,0.45,0.8,0.1], 'FontSize', 14, ...
        'ForegroundColor', [1,1,1], 'BackgroundColor', [1,0.84,0],...
        'HorizontalAlignment', 'center');

    %% Left Menu Callback Functions
    function launchSimulation(~, ~)
        % Reset real-time arrays.
        setappdata(f, 'rtLapTimes', []);
        setappdata(f, 'rtBrakeZones', []);
        setappdata(f, 'rtTireWear', []);
        setappdata(f, 'rtERS', []);
        % Clear any final upgrade snapshot so that live tally is computed freshly.
        setappdata(f, 'finalUpgrade', []);
        % Also clear the rtBaseSpeed array.
        setappdata(f, 'rtBaseSpeed', []);
        populateSimulate();
    end

    %% Nested Function: Populate Simulation Panel (Live)
    function populateSimulate(~, ~)
        delete(allchild(simPanel));
        axSim = axes('Parent', simPanel, 'Units', 'normalized','Position',[0.1,0.15,0.8,0.75]);
        axis(axSim, 'equal'); hold(axSim, 'on');
        axSim.XLim = [0 100]; axSim.YLim = [0 100]; axSim.Color = [0 0 0];
        centerX = 50; centerY = 50; radiusX = 40; radiusY = 30;
        theta = linspace(0,2*pi,300);
        trackX = centerX + radiusX*cos(theta);
        trackY = centerY + radiusY*sin(theta);
        patch(axSim, trackX, trackY, [0.5 0.5 0.5], 'EdgeColor', 'none');
        plot(axSim, trackX, trackY, 'w-', 'LineWidth', 3);
        % Load persistent stats for car.
        try
            S = load('car_stats.mat','car');
            if isfield(S, 'car')
                car = S.car;
            else
                car = struct('totalLaps',0,'upgradePoints',0,...
                    'upgrades',struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
            end
        catch
            car = struct('totalLaps',0,'upgradePoints',0,...
                'upgrades',struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
        end
        engineUpgrade = car.upgrades.engine;
        playerSpeed = 0.05 + 0.005 * engineUpgrade;
        % Get current speed multiplier.
        multiplier = getappdata(f, 'speedMultiplier');
        player_t = 0; opponent_t = 0; playerLap = 0; opponentLap = 0;
        player_x = centerX + radiusX*cos(player_t);
        player_y = centerY + radiusY*sin(player_t);
        opponent_x = centerX + radiusX*cos(opponent_t);
        opponent_y = centerY + radiusY*sin(opponent_t);
        playerCarHandle = plot(axSim, player_x, player_y, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        opponentCarHandle = plot(axSim, opponent_x, opponent_y, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
        playerLapText = text(axSim, 5, 95, sprintf('Player Laps: %d', playerLap),...
            'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
        opponentLapText = text(axSim, 5, 85, sprintf('Opponent Laps: %d', opponentLap),...
            'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
        % Add Toggle 2x Speed button in the simulation panel.
        uicontrol('Parent', simPanel, 'Style', 'pushbutton', 'String', 'Toggle 2x Speed',...
            'Units', 'normalized', 'Position', [0.8, 0.85, 0.15, 0.1], 'FontSize', 10, ...
            'Callback', @toggleSpeed);
        % End Race button.
        uicontrol('Parent', simPanel, 'Style', 'pushbutton', 'String', 'End Race',...
            'Units', 'normalized', 'Position', [0.35,0.01,0.3,0.1], 'FontSize', 12, ...
            'Callback', @(src, event) endRaceCallback());
        simulationRunning = true;
        prev_player_t = player_t; prev_opponent_t = opponent_t;
        simTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @updateSimulation);
        start(simTimer);
        
        % Store simulation data.
        simData.playerLap = playerLap;
        simData.opponentLap = opponentLap;
        simData.player_x = player_x;
        simData.player_y = player_y;
        simData.opponent_x = opponent_x;
        simData.opponent_y = opponent_y;
        simData.simTimer = simTimer;
        setappdata(f, 'simData', simData);
        
        function toggleSpeed(~, ~)
            % Toggle the speed multiplier between 1 and 2.
            currentMult = getappdata(f, 'speedMultiplier');
            if currentMult == 1
                setappdata(f, 'speedMultiplier', 2);
            else
                setappdata(f, 'speedMultiplier', 1);
            end
        end
        
        function updateSimulation(~, ~)
            if ~simulationRunning || ~ishandle(axSim) || ~isvalid(f)
                stop(simTimer); delete(simTimer); return;
            end
            prev_player_t = player_t; prev_opponent_t = opponent_t;
            multiplier = getappdata(f, 'speedMultiplier');
            player_t = mod(player_t + playerSpeed * multiplier, 2*pi);
            opponent_t = mod(opponent_t + 0.06, 2*pi);
            if player_t < prev_player_t
                playerLap = playerLap + 1;
                set(playerLapText, 'String', sprintf('Player Laps: %d', playerLap));
                newLapTime = 28 + 4 * rand;
                if isempty(getappdata(f, 'rtTireWear'))
                    newBrake = randi([1,2]);
                    newTire = 10 + 5 * newBrake + randn() * 0.5;
                else
                    newBrake = randi([1,3]);
                    rtTireWear = getappdata(f, 'rtTireWear');
                    newTireIncrement = 5 + 2 * newBrake + 0.05 * (60 + randi([0,20]) - 60) + randn() * 0.5;
                    newTireIncrement = max(newTireIncrement, 0);
                    newTire = rtTireWear(end) + newTireIncrement;
                end
                newERS = 60 + randi([0,20]) + randn() * 0.5;
                rtLapTimes = getappdata(f, 'rtLapTimes');
                rtBrakeZones = getappdata(f, 'rtBrakeZones');
                rtTireWear = getappdata(f, 'rtTireWear');
                rtERS = getappdata(f, 'rtERS');
                rtLapTimes(end+1) = newLapTime;
                rtBrakeZones(end+1) = newBrake;
                if isempty(rtTireWear)
                    rtTireWear(end+1) = 10 + 5 * newBrake + randn() * 0.5;
                else
                    rtTireWear(end+1) = newTire;
                end
                rtERS(end+1) = newERS;
                setappdata(f, 'rtLapTimes', rtLapTimes);
                setappdata(f, 'rtBrakeZones', rtBrakeZones);
                setappdata(f, 'rtTireWear', rtTireWear);
                setappdata(f, 'rtERS', rtERS);
                updateRealtimePerformanceGraphs();
                updateRealtimeAnalysis();
            end
            if opponent_t < prev_opponent_t
                opponentLap = opponentLap + 1;
                set(opponentLapText, 'String', sprintf('Opponent Laps: %d', opponentLap));
            end
            player_x = centerX + radiusX * cos(player_t);
            player_y = centerY + radiusY * sin(player_t);
            opponent_x = centerX + radiusX * cos(opponent_t);
            opponent_y = centerY + radiusY * sin(opponent_t);
            set(playerCarHandle, 'XData', player_x, 'YData', player_y);
            set(opponentCarHandle, 'XData', opponent_x, 'YData', opponent_y);
            drawnow limitrate;
            % Update simulation data.
            simData = getappdata(f, 'simData');
            simData.playerLap = playerLap;
            simData.opponentLap = opponentLap;
            simData.player_x = player_x;
            simData.player_y = player_y;
            simData.opponent_x = opponent_x;
            simData.opponent_y = opponent_y;
            setappdata(f, 'simData', simData);
            updateLiveUpgrade(f, upgradePanel);
            % Store current base speed in rtBaseSpeed for AI analysis.
            rtBaseSpeed = getappdata(f, 'rtBaseSpeed');
            if isempty(rtBaseSpeed)
                rtBaseSpeed = [];
            end
            rtBaseSpeed(end+1) = playerSpeed;
            setappdata(f, 'rtBaseSpeed', rtBaseSpeed);
        end
        
        function updateRealtimePerformanceGraphs()
            if ~ishandle(performancePanel), return; end
            delete(allchild(performancePanel));
            rtLapTimes = getappdata(f, 'rtLapTimes');
            if ~isempty(rtLapTimes)
                numLaps = length(rtLapTimes);
                laps = 1:numLaps;
                ax1 = subplot(2,2,1, 'Parent', performancePanel);
                plot(ax1, laps, rtLapTimes, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0 0.4470 0.7410]);
                title(ax1, 'Player Lap Times', 'FontSize', 12, 'FontWeight', 'bold', 'Color',[1 1 1]);
                xlabel(ax1, 'Lap', 'Color',[1 1 1]); ylabel(ax1, 'Time (s)', 'Color',[1 1 1]); 
                grid(ax1, 'on');
                
                ax2 = subplot(2,2,2, 'Parent', performancePanel);
                plot(ax2, laps, getappdata(f, 'rtTireWear'), '-s', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0.8500 0.3250 0.0980]);
                title(ax2, 'Player Tire Wear', 'FontSize', 12, 'FontWeight', 'bold', 'Color',[1 1 1]);
                xlabel(ax2, 'Lap', 'Color',[1 1 1]); ylabel(ax2, 'Wear (%)', 'Color',[1 1 1]);
                grid(ax2, 'on');
                
                ax3 = subplot(2,2,3, 'Parent', performancePanel);
                plot(ax3, laps, getappdata(f, 'rtBrakeZones'), '-^', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0.9290 0.6940 0.1250]);
                title(ax3, 'Player Hard Brakes', 'FontSize', 12, 'FontWeight', 'bold', 'Color',[1 1 1]);
                xlabel(ax3, 'Lap', 'Color',[1 1 1]); ylabel(ax3, 'Count', 'Color',[1 1 1]);
                grid(ax3, 'on');
                
                ax4 = subplot(2,2,4, 'Parent', performancePanel);
                plot(ax4, laps, getappdata(f, 'rtERS'), '-d', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0.4940 0.1840 0.5560]);
                title(ax4, 'Player ERS Usage', 'FontSize', 12, 'FontWeight', 'bold', 'Color',[1 1 1]);
                xlabel(ax4, 'Lap', 'Color',[1 1 1]); ylabel(ax4, 'Usage (%)', 'Color',[1 1 1]);
                grid(ax4, 'on');
            end
        end
        
        function updateRealtimeAnalysis()
            if ~ishandle(analyzePanel), return; end
            analysisCtrl = findobj(analyzePanel, 'Style', 'edit');
            if isempty(analysisCtrl) || ~ishandle(analysisCtrl)
                delete(allchild(analyzePanel));
                analysisCtrl = uicontrol('Parent', analyzePanel, 'Style', 'edit',...
                    'String', 'Real-Time Analysis: waiting for lap data...',...
                    'Units', 'normalized', 'Position', [0.05,0.05,0.9,0.9],...
                    'FontSize', 12, 'Max', 10, 'Min', 1, 'HorizontalAlignment', 'left',...
                    'ForegroundColor', [1,1,1], 'BackgroundColor', [0,0,0.5], 'Enable', 'inactive');
            end
            rtLapTimes = getappdata(f, 'rtLapTimes');
            rtBrakeZones = getappdata(f, 'rtBrakeZones');
            rtTireWear = getappdata(f, 'rtTireWear');
            rtERS = getappdata(f, 'rtERS');
            analysisStr = '';
            if ~isempty(rtLapTimes)
                avgLapTime = mean(rtLapTimes);
                stdLapTime = std(rtLapTimes);
                avgBrakes = mean(rtBrakeZones);
                avgTireWear = mean(rtTireWear);
                avgERS = mean(rtERS);
                analysisStr = sprintf('Real-Time Analysis\n---------------------------\nAvg Lap Time: %.2f s\nStd Dev: %.2f s\nAvg Hard Brakes: %.2f\nAvg Tire Wear: %.2f%%\nAvg ERS Usage: %.2f%%',...
                    avgLapTime, stdLapTime, avgBrakes, avgTireWear, avgERS);
                rtBaseSpeed = getappdata(f, 'rtBaseSpeed');
                if length(rtLapTimes) >= 5
                    if all(rtBaseSpeed == rtBaseSpeed(1))
                        if avgLapTime > 32
                            aiSuggestion = 'AI Suggestion: Upgrade engine for faster laps.';
                        else
                            aiSuggestion = 'AI Suggestion: Base speed seems optimal.';
                        end
                    elseif ~isempty(rtBaseSpeed) && length(rtLapTimes)==length(rtBaseSpeed)
                        mdl = fitlm(rtBaseSpeed, rtLapTimes);
                        predictedLapTime = predict(mdl, mean(rtBaseSpeed)*1.1);
                        if predictedLapTime < avgLapTime
                            aiSuggestion = 'AI Suggestion: Increase base speed for faster laps.';
                        else
                            aiSuggestion = 'AI Suggestion: Base speed seems optimal.';
                        end
                    else
                        aiSuggestion = '';
                    end
                    if ~isempty(aiSuggestion)
                        analysisStr = [analysisStr, sprintf('\n\n%s', aiSuggestion)];
                    end
                end
                set(analysisCtrl, 'String', analysisStr);
            end
        end
    end

    %% Nested Function: populateUpgrade (Initial persistent upgrade tally)
    function populateUpgrade()
        delete(allchild(upgradePanel));
        if isfile('car_stats.mat')
            S = load('car_stats.mat','car');
            if isfield(S, 'car')
                car = S.car;
            else
                car = struct('totalLaps',0,'upgradePoints',0,...
                    'upgrades',struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
            end
        else
            car = struct('totalLaps',0,'upgradePoints',0,...
                'upgrades',struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
        end
        liveTotal = car.totalLaps;
        livePoints = car.upgradePoints;
        if liveTotal > 0
            modLaps = mod(liveTotal,5);
            if modLaps == 0
                lapsNeeded = 5;
            else
                lapsNeeded = 5 - modLaps;
            end
        else
            lapsNeeded = 5;
        end
        delete(allchild(upgradePanel));
        uicontrol('Parent', upgradePanel, 'Style', 'text', 'String', ...
            sprintf('Live Total Laps: %d\nLive Upgrade Points: %d\nYou need %d more laps\nto earn 1 upgrade point.',...
            liveTotal, livePoints, lapsNeeded),...
            'Units', 'normalized', 'Position', [0.05,0.6,0.9,0.35], 'FontSize', 14, ...
            'ForegroundColor', [1,1,1], 'BackgroundColor', [0,0,0.5], 'HorizontalAlignment', 'center', 'FontName','Courier New');
        parts = {'Engine','Tires','Brakes','Aero','ERS'};
        fields = {'engine','tires','brakes','aero','ers'};
        for i = 1:length(parts)
            uicontrol('Parent', upgradePanel, 'Style', 'pushbutton', ...
                'String', sprintf('Upgrade %s (Lv %d)', parts{i}, car.upgrades.(fields{i})), ...
                'Units', 'normalized', 'Position', [0.05,0.6 - 0.12*i, 0.9,0.1], 'FontSize', 12, ...
                'ForegroundColor', [1,1,1], 'BackgroundColor', [0,0,0.5], 'FontName','Courier New', ...
                'Callback', @(src,event) liveUpgradePart(fields{i}, f, upgradePanel));
        end
    end

    %% End of main function.
    
    %% Nested Function: showRawData
    function showRawData(~, ~)
        % Retrieve raw data from appdata:
        rtLapTimes = getappdata(f, 'rtLapTimes');
        rtBrakeZones = getappdata(f, 'rtBrakeZones');
        rtTireWear = getappdata(f, 'rtTireWear');
        rtERS = getappdata(f, 'rtERS');
        rtBaseSpeed = getappdata(f, 'rtBaseSpeed');
        
        % Find the minimum length among all arrays
        n = min([length(rtLapTimes), length(rtBrakeZones), length(rtTireWear), length(rtERS), length(rtBaseSpeed)]);
        if n == 0
            warndlg('No raw data available.');
            return;
        end
        
        % Trim all arrays to the minimum length.
        rtLapTimes = rtLapTimes(1:n);
        rtBrakeZones = rtBrakeZones(1:n);
        rtTireWear = rtTireWear(1:n);
        rtERS = rtERS(1:n);
        rtBaseSpeed = rtBaseSpeed(1:n);
        
        % Create a table of raw data.
        T = table(rtLapTimes(:), rtBrakeZones(:), rtTireWear(:), rtERS(:), rtBaseSpeed(:), ...
            'VariableNames', {'LapTime','BrakeZones','TireWear','ERS','BaseSpeed'});
        
        % Create a new figure with a uitable.
       rawFig = uifigure('Name', 'Raw Data', 'Position', [100,100,600,400]);
        uitable(rawFig, 'Data', T, 'Units', 'normalized', 'Position', [0,0,1,1]);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local Function: updateLiveUpgrade (updates the live upgrade panel)
function updateLiveUpgrade(f, upgradePanel)
    % If a race is ongoing, use simData; otherwise, use persistent stats.
    simData = getappdata(f, 'simData');
    if isempty(simData)
        try
            S = load('car_stats.mat','car');
            if isfield(S, 'car')
                car = S.car;
            else
                car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                    struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
            end
        catch
            car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
        end
        liveTotal = car.totalLaps;
        livePoints = car.upgradePoints;
    else
        try
            S = load('car_stats.mat','car');
            if isfield(S, 'car')
                car = S.car;
            else
                car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                    struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
            end
        catch
            car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
        end
        currentSimLaps = simData.playerLap;
        liveTotal = car.totalLaps + currentSimLaps;
        liveAdditional = floor(currentSimLaps / 5);
        livePoints = car.upgradePoints + liveAdditional;
    end

    if liveTotal > 0
        modLaps = mod(liveTotal, 5);
        if modLaps == 0
            lapsNeeded = 5;
        else
            lapsNeeded = 5 - modLaps;
        end
    else
        lapsNeeded = 5;
    end
    delete(allchild(upgradePanel));
    uicontrol('Parent', upgradePanel, 'Style', 'text', 'String', ...
        sprintf('Live Total Laps: %d\nLive Upgrade Points: %d\n\nYou need %d more laps\nto earn 1 upgrade point.',...
        liveTotal, livePoints, lapsNeeded),...
        'Units', 'normalized', 'Position', [0.05,0.55,0.9,0.35], 'FontSize', 14, ...
        'ForegroundColor', [1,1,1],'BackgroundColor', [0,0,0.5], 'HorizontalAlignment', 'center', 'FontName','Courier New');
    parts = {'Engine','Tires','Brakes','Aero','ERS'};
    fields = {'engine','tires','brakes','aero','ers'};
    for i = 1:length(parts)
        uicontrol('Parent', upgradePanel, 'Style', 'pushbutton', ...
            'String', sprintf('Upgrade %s (Lv %d)', parts{i}, car.upgrades.(fields{i})), ...
            'Units', 'normalized', 'Position', [0.05,0.55 - 0.12*i, 0.9,0.1], 'FontSize', 12, ...
            'ForegroundColor', [1,1,1], 'FontName','Courier New', ...
            'BackgroundColor', [0,0,0.5],'Callback', @(src,event) liveUpgradePart(fields{i}, f, upgradePanel));
    end
end

function liveUpgradePart(part, f, upgradePanel)
    try
        if isfile('car_stats.mat')
            S = load('car_stats.mat','car');
            if isfield(S, 'car')
                car = S.car;
            else
                car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                    struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
            end
        else
            car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
        end
    catch
        car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
            struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
    end
    simData = getappdata(f, 'simData');
    if isempty(simData)
        currentSimLaps = 0;
    else
        currentSimLaps = simData.playerLap;
    end
    liveTotal = car.totalLaps + currentSimLaps;
    liveAdditional = floor(currentSimLaps / 5);
    livePoints = car.upgradePoints + liveAdditional;
    if livePoints > 0
        % Deduct from persistent upgradePoints.
        if car.upgradePoints > 0
            car.upgradePoints = car.upgradePoints - 1;
        end
        car.upgrades.(part) = car.upgrades.(part) + 1;
        save('car_stats.mat','car');
        updateLiveUpgrade(f, upgradePanel);
    else
        warndlg('Not enough upgrade points!');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local Function: endRaceCallback (Final Data Generation)
function endRaceCallback()
    f = gcf;
    simData = getappdata(f, 'simData');
    if isempty(simData)
        warndlg('No simulation data found!');
        return;
    end
    if isfield(simData, 'simTimer') && isvalid(simData.simTimer)
        stop(simData.simTimer);
        delete(simData.simTimer);
    end
    if simData.playerLap > 0
        playerLapTimes = linspace(28, 32, simData.playerLap) + randn(1, simData.playerLap)*0.5;
        playerBrakeZones = zeros(1, simData.playerLap);
        for i = 1:simData.playerLap
            if i <= 5
                playerBrakeZones(i) = randi([1, 2]);
            else
                playerBrakeZones(i) = randi([1, 3]);
            end
        end
        playerERS = 60 + randi([0, 20], 1, simData.playerLap) + randn(1, simData.playerLap)*0.5;
        playerTireWear = zeros(1, simData.playerLap);
        for i = 1:simData.playerLap
            if i == 1
                playerTireWear(i) = 10 + 5*playerBrakeZones(i) + randn()*0.5;
            else
                incremental = 5 + 2*playerBrakeZones(i) + 0.05*(playerERS(i)-60) + randn()*0.5;
                incremental = max(incremental, 0);
                playerTireWear(i) = playerTireWear(i-1) + incremental;
            end
        end
    else
        playerLapTimes = [];
        playerBrakeZones = [];
        playerTireWear = [];
        playerERS = [];
    end
    try
        if isfile('car_stats.mat')
            S = load('car_stats.mat','car');
            if isfield(S, 'car')
                car = S.car;
            else
                car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                    struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
            end
        else
            car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
                struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
        end
    catch
        car = struct('totalLaps',0,'upgradePoints',0,'upgrades',...
            struct('engine',0,'tires',0,'brakes',0,'aero',0,'ers',0));
    end
    newPoints = floor(simData.playerLap / 5);
    car.totalLaps = car.totalLaps + simData.playerLap;
    car.upgradePoints = car.upgradePoints + newPoints;
    save('car_stats.mat', 'car');
    raceData.playerPos = [simData.player_x, simData.player_y];
    raceData.opponentPos = [simData.opponent_x, simData.opponent_y];
    raceData.playerLapTimes = playerLapTimes;
    raceData.playerBrakeZones = playerBrakeZones;
    raceData.playerTireWear = playerTireWear;
    raceData.playerERS = playerERS;
    raceData.opponentLapCount = simData.opponentLap;
    save('race_data.mat', 'raceData');
    % After race end, clear simData so live upgrade uses persistent stats.
    setappdata(f, 'simData', []);
    msgbox(sprintf('Race Ended!\nPlayer Laps: %d\nOpponent Laps: %d', simData.playerLap, simData.opponentLap));
end
