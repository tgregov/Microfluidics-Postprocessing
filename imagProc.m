clc;
clear variables;
close all;
warning('off');

% Comments:
% - only works if the input file is a video (> 1 frame)

% Import video
fileName = 'chip4_500fps_rec10.avi';
v = VideoReader(fileName);
video = read(v);
sizeV = size(video);
videoGS = reshape(video, sizeV(1), sizeV(2), sizeV(4));
videoGS = im2double(videoGS);
fprintf(['<strong>Post-processing of the file ', fileName, '</strong>\n']);
disp(['The video has ', num2str(v.NumberOfFrames), ' frames.']);

% Remove the background
videoMedian = median(videoGS, 3);
videoMedians = zeros(sizeV(1), sizeV(2), sizeV(4));
for i = 1:sizeV(4)
    videoMedians(:, :, i) = videoMedian(:, :);
end
videoResultBefore = imabsdiff(videoMedians, videoGS);
videoResultAfter = imabsdiff(videoMedians, videoGS);

%% Before pico-injection
% Adjust contrast
% c = 70;
% f = figure('Name', ...
%     'Traitement de l''image: Before pico-injection threshold');
% img = videoResultBefore(:, :, int64(sizeV(4)/2));
% while(true)
%     imgTemp = imadjust(img, [0, c/256]);
%     imshow(imgTemp);
%     textThres = text(50, 50, ['$c = $ ', num2str(c)], 'Color', 'Red', ...
%         'FontSize', 20);
%     set(textThres, 'interpreter', 'latex');
%     
%     pause;
%     currkey = get(gcf,'CurrentKey');
%     if strcmp(currkey, 'return')
%         break;
%     elseif strcmp(currkey, 'rightarrow')
%         c = c + 1;
%     elseif strcmp(currkey, 'leftarrow')
%         c = c - 1;
%         if(c < 1)
%             c = 1;
%         end
%     end
% end
% close(f);
%
% for i = 1:sizeV(4)
%     videoResultBefore(:, :, i) = ...
%         imadjust(videoResultBefore(:, :, i), [0, c/256]);
% end

% Adjust thresold
t = 30;
f = figure('Name', 'Image processing: Before pico-injection threshold');
img = videoResultBefore(:, :, int64(sizeV(4)/2));
while(true)
    imgTemp = imbinarize(img, t/255);
    imshow(imgTemp);
    textThres = text(50, 50, ['$t = $ ', num2str(t)], 'Color', 'Red', ...
        'FontSize', 20);
    set(textThres, 'interpreter', 'latex');
    
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    elseif strcmp(currkey, 'rightarrow')
        t = t + 1;
    elseif strcmp(currkey, 'leftarrow')
        t = t - 1;
        if(t < 1)
            t = 1;
        end
    end
end
close(f);

for i = 1:sizeV(4)
    videoResultBefore(:, :, i) = ...
        imbinarize(videoResultBefore(:, :, i), t/255);
end

% Remove small particules
part = 30;
f = figure('Name', ...
    'Image processing: Before pico-injection remove small particules');
img = videoResultBefore(:, :, int64(sizeV(4)/2));
while(true)
    imgTemp = bwareaopen(img, part);
    imshow(imgTemp);
    textPart = text(50, 50, ['$Size\ particules = $ ', num2str(part)], ...
        'Color', 'Red', 'FontSize', 20);
    set(textPart, 'interpreter', 'latex');
    
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    elseif strcmp(currkey, 'rightarrow')
        part = part + 1;
    elseif strcmp(currkey, 'leftarrow')
        part = part - 1;
        if(part < 0)
            part = 0;
        end
    end
end
close(f);

for i = 1:sizeV(4)
    videoResultBefore(:, :, i) = ...
        bwareaopen(videoResultBefore(:, :, i), part);
end

% Choose window
f = figure('Name', 'Image processing: scaling before pico-injection');
imshow(videoGS(:, :, int64(sizeV(4)/2)));
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
    int64(abs(xB(2)-xB(1))) + 1, sizeV(4));
for i = 1:sizeV(4)
    videoCroppedBefore(:, :, i) = imcrop(videoResultBefore(:, :, i), ...
        [xB(1), yB(1), abs(xB(2)-xB(1)), abs(yB(2)-yB(1))]);
end

% Remove elements on border
for i = 1:sizeV(4)
   videoCroppedBefore(:, :, i) = ...
       imclearborder(videoCroppedBefore(:, :, i)); 
end

% Fit a bounding rectangle
LBefore = [];
lastX = Inf;
lastNb = 1;

for i = 1:sizeV(4)
  box = regionprops(videoCroppedBefore(:, :, i), 'BoundingBox');
  [m, n] = size(box);
  
  if(m == 1)
      boxArray = box.BoundingBox;
      
      if(boxArray(1) <= lastX)
        LBefore = [LBefore, boxArray(3)];
        lastNb = 1;
      else
        LBefore(end) = (LBefore(end)*lastNb + boxArray(3))/(lastNb + 1);
        lastNb = lastNb + 1;
      end
      
      lastX = boxArray(1);
  end
end

% Remove unprobable results (quite arbitrary...)
LBefore = LBefore(LBefore > mean(LBefore)/2);
disp([num2str(length(LBefore)), ...
    ' droplets were found before pico-injection.']);


%% After pico-injection
% Adjust contrast
% c = 70;
% f = figure('Name', ...
%     'Traitement de l''image: After pico-injection threshold');
% img = videoResultAfter(:, :, int64(sizeV(4)/2));
% while(true)
%     imgTemp = imadjust(img, [0, c/256]);
%     imshow(imgTemp);
%     textThres = text(50, 50, ['$c = $ ', num2str(c)], 'Color', 'Red', ...
%         'FontSize', 20);
%     set(textThres, 'interpreter', 'latex');
%     
%     pause;
%     currkey = get(gcf,'CurrentKey');
%     if strcmp(currkey, 'return')
%         break;
%     elseif strcmp(currkey, 'rightarrow')
%         c = c + 1;
%     elseif strcmp(currkey, 'leftarrow')
%         c = c - 1;
%         if(c < 1)
%             c = 1;
%         end
%     end
% end
% close(f);
%
% for i = 1:sizeV(4)
%     videoResultAfter(:, :, i) = ...
%         imadjust(videoResultAfter(:, :, i), [0, c/256]);
% end

% Adjust thresold
t = 30;
f = figure('Name', 'Image processing: After pico-injection threshold');
img = videoResultAfter(:, :, int64(sizeV(4)/2));
while(true)
    imgTemp = imbinarize(img, t/255);
    imshow(imgTemp);
    textThres = text(50, 50, ['$t = $ ', num2str(t)], 'Color', 'Red', ...
        'FontSize', 20);
    set(textThres, 'interpreter', 'latex');
    
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    elseif strcmp(currkey, 'rightarrow')
        t = t + 1;
    elseif strcmp(currkey, 'leftarrow')
        t = t - 1;
        if(t < 1)
            t = 1;
        end
    end
end
close(f);

for i = 1:sizeV(4)
    videoResultAfter(:, :, i) = ...
        imbinarize(videoResultAfter(:, :, i), t/255);
end

% Remove small particules
part = 30;
f = figure('Name', ...
    'Image processing: After pico-injection remove small particules');
img = videoResultAfter(:, :, int64(sizeV(4)/2));
while(true)
    imgTemp = bwareaopen(img, part);
    imshow(imgTemp);
    textPart = text(50, 50, ['$Size\ particules = $ ', num2str(part)], ...
        'Color', 'Red', 'FontSize', 20);
    set(textPart, 'interpreter', 'latex');
    
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    elseif strcmp(currkey, 'rightarrow')
        part = part + 1;
    elseif strcmp(currkey, 'leftarrow')
        part = part - 1;
        if(part < 0)
            part = 0;
        end
    end
end
close(f);

for i = 1:sizeV(4)
    videoResultAfter(:, :, i) = ...
        bwareaopen(videoResultAfter(:, :, i), part);
end

% Choose window
f = figure('Name', 'Image processing: scaling after pico-injection');
imshow(videoGS(:, :, int64(sizeV(4)/2)));
hB = rectangle('Position', [xB(1), yB(1), ...
    abs(xB(2)-xB(1)), abs(yB(2)-yB(1))], 'EdgeColor', 'Blue');
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

disp('Click on enter');
pause;
prompt = 'How many drops between the two rectangles? ';
numOfDrops = input(prompt);

videoCroppedAfter = zeros(int64(abs(yA(2)-yA(1))) + 1, ...
    int64(abs(xA(2)-xA(1))) + 1, sizeV(4));
for i = 1:sizeV(4)
    videoCroppedAfter(:, :, i) = imcrop(videoResultAfter(:, :, i), ...
        [xA(1), yA(1), abs(xA(2)-xA(1)), abs(yA(2)-yA(1))]);
end

% Remove elements on border
for i = 1:sizeV(4)
   videoCroppedAfter(:, :, i) = imclearborder(videoCroppedAfter(:, :, i)); 
end

% Fit a bounding rectangle
LAfter = [];
lastX = Inf;
lastNb = 1;

for i = 1:sizeV(4)
  box = regionprops(videoCroppedAfter(:, :, i), 'BoundingBox');
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
LAfter = LAfter(LAfter > mean(LAfter)/2);
disp([num2str(length(LAfter)), ...
    ' droplets were found after pico-injection.']);

% Change of length due to pico-injection
str = 'Not the same number of drops before and after pico-injection';
enoughDrop = false;
if length(LBefore) == length(LAfter)
    if length(LBefore) > numOfDrops+1
        enoughDrop = true;
        diffL = LAfter(numOfDrops+1:end) - LBefore(1:end-numOfDrops);
    else
        fprintf('Not enough drops detected');
    end
else
    fprintf(2, ['<strong>WARNING: ', str, '</strong>\n']);
end


%% Display the results

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

% Change of length
if(enoughDrop)
    figure('Name', 'Change of Length due to pico-injection');
    subplot(1, 2, 1);
    histogram(diffL, 'Normalization', 'pdf');
    % hist(diffL, sqrt(length(diffL)), 'Normalization', 'pdf');
    grid on;
    set(gca, 'Units', 'normalized', 'FontUnits', 'points', ...
        'FontWeight', 'normal', 'FontSize', 15, 'FontName','Times');
    xlabel('$\Delta L$ [pix]', 'interpreter', 'latex');
    ylabel('PDF [-]', 'interpreter', 'latex');
    xlim([0, 2*max(diffL)]);

    subplot(1, 2, 2);
    boxplot(diffL);
    grid on;
    set(gca, 'Units', 'normalized', 'FontUnits', 'points', ...
        'FontWeight', 'normal', 'FontSize', 15, 'FontName','Times');
    ylabel('$\Delta L$ [pix]', 'interpreter', 'latex');
    % ylim([0, 2*max(diffL)]);
end
