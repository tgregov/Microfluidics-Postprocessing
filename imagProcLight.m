clc;
clear variables;
close all;
warning('off');

% Import videos
fileNameBefore = 'cleanBefore.avi';
fileNameAfter = 'cleanAfterBis.avi';
vBefore = VideoReader(fileNameBefore);
vAfter = VideoReader(fileNameAfter);
videoBefore = read(vBefore);
videoAfter = read(vAfter);
sizeVBefore = size(videoBefore);
sizeVAfter = size(videoBefore);
if(length(sizeVBefore) ~= 4)
    fprintf(2, ['<strong>WARNING: THE VIDEO SHOULD HAVE MORE THAN 1', ...
        ' FRAME FOR THIS SCRIPT TO WORK</strong>\n']);
    return;
end
if(sizeVBefore ~= sizeVAfter)
      fprintf(2, ['<strong>WARNING: THE TWO VIDEOS SHOULD HAVE THE', ...
        ' SAME NUMBER OF FRAMES FOR THIS SCRIPT TO WORK</strong>\n']);
    return;
end

% colorChoice = 1; (the video should be black & white !)
videoGSBefore = reshape(videoBefore, sizeVBefore(1), sizeVBefore(2), ...
    sizeVBefore(4));
videoGSAfter = reshape(videoAfter, sizeVAfter(1), sizeVAfter(2), ...
    sizeVAfter(4));
clear videoBefore;
clear videoAfter,
videoGSBefore = imcomplement(im2double(videoGSBefore));
videoGSAfter = imcomplement(im2double(videoGSAfter));
fprintf(['<strong>Post-processing of the files ', ...
    fileNameBefore, ' and ', fileNameAfter, '</strong>\n']);
disp(['The videos have ', num2str(vBefore.NumberOfFrames), ' frames.']);

% Remove the backgrounds
% videoMedianBefore = median(videoGSBefore, 3);
% videoMedianAfter = median(videoGSAfter, 3);
% videoMediansBefore = zeros(sizeVBefore(1), sizeVBefore(2), ...
% sizeVBefore(4));
% videoMediansAfter = zeros(sizeVAfter(1), sizeVAfter(2), sizeVAfter(4));
% for i = 1:sizeVBefore(4)
%     videoMediansBefore(:, :, i) = videoMedianBefore(:, :);
%     videoMediansAfter(:, :, i) = videoMedianAfter(:, :);
% end
%videoResultBefore = imabsdiff(videoMediansBefore, videoGSBefore);
%videoResultAfter = imabsdiff(videoMediansAfter, videoGSAfter);
%clear videoMediansBefore;
%clear videoMediansAfter;
videoResultBefore = videoGSBefore;
videoResultAfter = videoGSAfter;

%% Before pico-injection
fprintf(['\nPart I - Before pico-injection\n']);
fprintf(['-------------------------------------------------------\n']);

% Choose window
f = figure('Name', 'Image processing: scaling before pico-injection');
imshow(videoGSBefore(:, :, 1));
while(true)
    [xB, yB] = ginputc(2, 'Color', 'b', 'LineWidth', 1);
    xB = double(int64(xB));
    yB = double(int64(yB));
    h = rectangle('Position', [xB(1), yB(1), ...
        abs(xB(2)-xB(1)), abs(yB(2)-yB(1))], 'EdgeColor', 'Red');
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    else
        delete(h);
    end
end
close(f);

videoCroppedBefore = zeros(int64(abs(yB(2)-yB(1))) + 1, ...
    int64(abs(xB(2)-xB(1))) + 1, sizeVBefore(4));
for i = 1:sizeVBefore(4)
    videoCroppedBefore(:, :, i) = imcrop(videoResultBefore(:, :, i), ...
        [xB(1), yB(1), abs(xB(2)-xB(1)), abs(yB(2)-yB(1))]);
end

% Remove elements on border
for i = 1:sizeVBefore(4)
   videoCroppedBefore(:, :, i) = ...
       imclearborder(...
       videoCroppedBefore(:, :, i)); 
end

% Fit a bounding rectangle
LBefore = [];
lastX = Inf;
lastNb = 1;

for i = 1:sizeVBefore(4)
    cc = bwconncomp(videoCroppedBefore(:, :, i), 8);
    box = regionprops(cc, 'BoundingBox');
    [m, n] = size(box);
    
    if(m == 1)
        boxArray = box.BoundingBox;
        
        if(boxArray(1) <= lastX)
            LBefore = [LBefore, boxArray(3)];
            lastNb = 1;
        else
            LBefore(end) = ...
                (LBefore(end)*lastNb + boxArray(3))/(lastNb + 1);
            lastNb = lastNb + 1;
        end
        
        lastX = boxArray(1);
    end
end

% Remove unprobable results (quite arbitrary...)
LBefore = LBefore(LBefore > mean(LBefore)*0.3);
disp([num2str(length(LBefore)), ...
    ' droplets were found before pico-injection.']);


%% After pico-injection
fprintf(['\nPart II - After pico-injection\n']);
fprintf(['-------------------------------------------------------\n']);

% Choose window
f = figure('Name', 'Image processing: scaling after pico-injection');
imshow(videoGSAfter(:, :, 1));
while(true)
    [xA, yA] = ginputc(2, 'Color', 'b', 'LineWidth', 1);
    xA = double(int64(xA));
    yA = double(int64(yA));
    h = rectangle('Position', [xA(1), yA(1), ...
        abs(xA(2)-xA(1)), abs(yA(2)-yA(1))], 'EdgeColor', 'Red');
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    else
        delete(h);
    end
end
close(f);

videoCroppedAfter = zeros(int64(abs(yA(2)-yA(1))) + 1, ...
    int64(abs(xA(2)-xA(1))) + 1, sizeVAfter(4));
for i = 1:sizeVAfter(4)
    videoCroppedAfter(:, :, i) = imcrop(videoResultAfter(:, :, i), ...
        [xA(1), yA(1), abs(xA(2)-xA(1)), abs(yA(2)-yA(1))]);
end

% Remove elements on border
for i = 1:sizeVAfter(4)
   videoCroppedAfter(:, :, i) = ...
       imclearborder(...
       videoCroppedAfter(:, :, i)); 
end

% Fit a bounding rectangle
LAfter = [];
lastX = Inf;
lastNb = 1;

for i = 1:sizeVAfter(4)
    cc = bwconncomp(videoCroppedAfter(:, :, i), 8);
    box = regionprops(cc, 'BoundingBox');
    [m, n] = size(box);
    
    if(m == 1)
        boxArray = box.BoundingBox;
                
        if(boxArray(1) <= lastX)
            LAfter = [LAfter, boxArray(3)];
            lastNb = 1;
        else
            LAfter(end) = (LAfter(end)*lastNb + boxArray(3))/(lastNb + 1);
            lastNb = lastNb + 1;
        end
        
        lastX = boxArray(1);
    end
end

% Remove unprobable results (quite arbitrary...)
LAfter = LAfter(LAfter > mean(LAfter)*0.3);
disp([num2str(length(LAfter)), ...
    ' droplets were found after pico-injection.']);

%% Compare before and after pico-injection
fprintf('\nPart III - Comparison\n');
fprintf(['-------------------------------------------------------\n']);
fprintf(2, ['<strong>We assume that the pico-injection process ', ...
    'is perfectly working.</strong>\n']);
f = figure('Name', ...
    ['Image processing: Number of drops between rectangles ?', ...
    ' <Press enter>']);
imshow(videoGSBefore(:, :, 1));
hB = rectangle('Position', [xB(1), yB(1), ...
    abs(xB(2)-xB(1)), abs(yB(2)-yB(1))], 'EdgeColor', 'Red');
hA = rectangle('Position', [xA(1), yA(1), ...
    abs(xA(2)-xA(1)), abs(yA(2)-yA(1))], 'EdgeColor', 'Red');
while(true)
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    end
end
close(f);

prompt = 'How many droplets between the two rectangles? ';
numOfDrops = input(prompt);

nDropletsComp = min(length(LBefore) - numOfDrops - 1, ...
    length(LAfter) - numOfDrops - 1);
disp([num2str(nDropletsComp), ' droplets were used for ', ...
    'the before/after pico-injection comparison.']);
LComp = LAfter(numOfDrops+1:numOfDrops+nDropletsComp) ...
        - LBefore(1:nDropletsComp);

% % Change of length due to pico-injection
% str = 'Not the same number of droplets before and after pico-injection.';
% enoughDrop = false;
% if length(LBefore) == length(LAfter)
%     if length(LBefore) > numOfDrops+1
%         enoughDrop = true;
%         diffL = LAfter(numOfDrops+1:end) - LBefore(1:end-numOfDrops);
%     else
%         fprintf('Not enough drops detected');
%     end
% else
%     fprintf(2, ['<strong>WARNING: ', str, '</strong>\n']);
% end

%% Velocity (before pico-injection)
fprintf(['\nPart IV - Velocity (before pico-injection)\n']);
fprintf(['-------------------------------------------------------\n']);

% Choose window
f = figure('Name', ['Image processing: scaling before pico-injection', ...
    ' for velocity']);
imshow(videoGSBefore(:, :, 1));
while(true)
    [xC, yC] = ginputc(2, 'Color', 'b', 'LineWidth', 1);
    xC = double(int64(xC));
    yC = double(int64(yC));
    h = rectangle('Position', [xC(1), yC(1), ...
        abs(xC(2)-xC(1)), abs(yC(2)-yC(1))], 'EdgeColor', 'Red');
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    else
        delete(h);
    end
end
close(f);

videoCroppedC = zeros(int64(abs(yC(2)-yC(1))) + 1, ...
    int64(abs(xC(2)-xC(1))) + 1, sizeVBefore(4));
for i = 1:sizeVBefore(4)
    videoCroppedC(:, :, i) = imcrop(videoResultBefore(:, :, i), ...
        [xC(1), yC(1), abs(xC(2)-xC(1)), abs(yC(2)-yC(1))]);
end

% Remove elements on border
for i = 1:sizeVBefore(4)
   videoCroppedC(:, :, i) = ...
       imclearborder(...
       videoCroppedC(:, :, i)); 
end

% Fit bounding rectangles
xCoordRecLast = [];
velocity = [];

for i = 1:sizeVBefore(4)
    cc = bwconncomp(videoCroppedC(:, :, i), 8);
    box = regionprops(cc, 'BoundingBox');
    [m, n] = size(box);
    
    if(m >= 1)
        xCoordRec = zeros(m, 1);
        
        for j = 1:m
            tab = box(j).BoundingBox;
            xCoordRec(j) = tab(1);
        end
        
        counter = 1;
        counterLast = 1;
        while(true)
            if(or(counter > size(xCoordRec), ...
                    counterLast > size(xCoordRecLast)))
                break;
            end
            
            if(xCoordRec(counter) >= xCoordRecLast(counterLast))
                velocity = [velocity, ...
                    xCoordRec(counter) - xCoordRecLast(counterLast)];
                counter = counter + 1;
                counterLast = counterLast + 1;
            else
                counter = counter + 1;
            end
        end
        
        xCoordRecLast = xCoordRec;
    end
end

% Remove unprobable results (quite arbitrary...)
velocity = velocity(velocity > mean(velocity)*0.3);
velocity = velocity(velocity < mean(velocity)*1/(0.3));

disp([num2str(length(velocity)), ' droplets were used for ', ...
    'the velocity measurement.']);

%% Display the results
fprintf('\nPart V - Results\n');
fprintf(['-------------------------------------------------------\n']);
% Before pico-injection
figure('Name', 'Length of the droplets before pico-injection');
subplot(1, 2, 1);
histogram(LBefore, 'Normalization', 'pdf');
% hist(LBefore, sqrt(length(LBefore)), 'Normalization', 'pdf');
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
xlabel('$L$ [pix]', 'interpreter', 'latex');
ylabel('PDF [-]', 'interpreter', 'latex');
xlim([0, 2*max(LBefore)]);

subplot(1, 2, 2);
boxplot(LBefore);
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
ylabel('$L$ [pix]', 'interpreter', 'latex');
% ylim([0, 2*max(LBefore)]);

disp('Before pico-injection:');
disp(['   - mean(L) = ', num2str(mean(LBefore)), ' pix']);
disp(['   - std(L) = ', num2str(std(LBefore)), ' pix']);

% After pico-injection
figure('Name', 'Length of the droplets after pico-injection');
subplot(1, 2, 1);
histogram(LAfter, 'Normalization', 'pdf');
% hist(Lafter, sqrt(length(LAfter)), 'Normalization', 'pdf');
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
xlabel('$L$ [pix]', 'interpreter', 'latex');
ylabel('PDF [-]', 'interpreter', 'latex');
xlim([0, 2*max(LAfter)]);

subplot(1, 2, 2);
boxplot(LAfter);
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
ylabel('$L$ [pix]', 'interpreter', 'latex');
% ylim([0, 2*max(LAfter)]);

disp('After pico-injection:');
disp(['   - mean(L) = ', num2str(mean(LAfter)), ' pix']);
disp(['   - std(L) = ', num2str(std(LAfter)), ' pix']);

% Comparison before/after
figure('Name', 'Added length of the droplets before/after pico-injection');
subplot(1, 2, 1);
histogram(LComp, 'Normalization', 'pdf');
% hist(Lafter, sqrt(length(LAfter)), 'Normalization', 'pdf');
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
xlabel('$\Delta L$ [pix]', 'interpreter', 'latex');
ylabel('PDF [-]', 'interpreter', 'latex');
xlim([0, 2*max(LComp)]);

subplot(1, 2, 2);
boxplot(LComp);
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
ylabel('$\Delta L$ [pix]', 'interpreter', 'latex');

disp('Comparison before/after pico-injection:');
disp(['   - mean(LComp) = ', num2str(mean(LComp)), ' pix']);
disp(['   - std(LComp) = ', num2str(std(LComp)), ' pix']);

% Velocity
figure('Name', 'Velocity the droplets (before pico-injection)');
subplot(1, 2, 1);
histogram(velocity, 'Normalization', 'pdf');
% hist(Lafter, sqrt(length(velocity)), 'Normalization', 'pdf');
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
xlabel('$v$ [pix/frame]', 'interpreter', 'latex');
ylabel('PDF [-]', 'interpreter', 'latex');
xlim([0, max(velocity)]);

subplot(1, 2, 2);
boxplot(velocity);
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
ylabel('$v$ [pix/frame]', 'interpreter', 'latex');
disp('Velocity (before pico-injection):');
disp(['   - mean(velocity) = ', num2str(mean(velocity)), ' pix/frame']);
disp(['   - std(velocity) = ', num2str(std(velocity)), ' pix/frame']);

% Change of length
% if(enoughDrop)
%     figure('Name', 'Change of Length due to pico-injection');
%     subplot(1, 2, 1);
%     histogram(diffL, 'Normalization', 'pdf');
%     % hist(diffL, sqrt(length(diffL)), 'Normalization', 'pdf');
%     grid on;
%     set(gca, 'Units', 'normalized', 'FontUnits', 'points', ...
%         'FontWeight', 'normal', 'FontSize', 15, 'FontName','Times');
%     xlabel('$\Delta L$ [pix]', 'interpreter', 'latex');
%     ylabel('PDF [-]', 'interpreter', 'latex');
%     xlim([0, 2*max(diffL)]);
% 
%     subplot(1, 2, 2);
%     boxplot(diffL);
%     grid on;
%     set(gca, 'Units', 'normalized', 'FontUnits', 'points', ...
%         'FontWeight', 'normal', 'FontSize', 15, 'FontName','Times');
%     ylabel('$\Delta L$ [pix]', 'interpreter', 'latex');
%     % ylim([0, 2*max(diffL)]);
% end

%% Delete the read video
delete(vBefore);

%% Save data
fileSaveName = [fileNameBefore, 'Results.mat'];
save(fileSaveName, 'LBefore', 'LAfter', 'LComp', 'velocity');