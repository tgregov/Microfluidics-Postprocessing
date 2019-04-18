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
videoResult = imabsdiff(videoMedians, videoGS);

% Adjust contrast
% c = 70;
% f = figure('Name', 'Traitement de l''image: threshold');
% img = videoResult(:, :, int64(sizeV(4)/2));
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

% Adjust thresold
t = 30;
f = figure('Name', 'Image processing: threshold');
img = videoResult(:, :, int64(sizeV(4)/2));
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
    videoResult(:, :, i) = imbinarize(videoResult(:, :, i), t/255);
end

% Remove small particules
for i = 1:sizeV(4)
    videoResult(:, :, i) = bwareaopen(videoResult(:, :, i), 30);
end

% Choose window
f = figure('Name', 'Image processing: scaling after pico-injection');
imshow(videoGS(:, :, int64(sizeV(4)/2)));
while(true)
    [x, y] = ginputc(2, 'Color', 'b', 'LineWidth', 1);
    x = double(int64(x));
    y = double(int64(y));
    h = rectangle('Position', ...
        [x(1), y(1), abs(x(2)-x(1)), abs(y(2)-y(1))], 'EdgeColor', 'Red');
    pause;
    currkey = get(gcf,'CurrentKey');
    if strcmp(currkey, 'return')
        break;
    else
        delete(h);
    end
end
close(f);

videoCropped = zeros(int64(abs(y(2)-y(1))) + 1, ...
    int64(abs(x(2)-x(1))) + 1, sizeV(4));
for i = 1:sizeV(4)
    videoCropped(:, :, i) = imcrop(videoResult(:, :, i), ...
        [x(1), y(1), abs(x(2)-x(1)), abs(y(2)-y(1))]);
end

% Remove elements on border
for i = 1:sizeV(4)
   videoCropped(:, :, i) = imclearborder(videoCropped(:, :, i)); 
end

% Fit a bounding rectangle
L = [];
lastX = Inf;
lastNb = 1;

for i = 1:sizeV(4)
  box = regionprops(videoCropped(:, :, i), 'BoundingBox'); 
  [m, n] = size(box);
  
  if(m == 1)
      boxArray = box.BoundingBox;
      
      if(boxArray(1) <= lastX)
        L = [L, boxArray(3)];
        lastNb = 1;
      else
        L(end) = (L(end)*lastNb + boxArray(3))/(lastNb + 1);
        lastNb = lastNb + 1;
      end
      
      lastX = boxArray(1);
  end
end

% Remove unprobable results (quite arbitrary...)
L = L(L > mean(L)/2);
disp([num2str(length(L)), ' droplets were found.']);

% Display the results
figure('Name', 'Length of the droplets');
subplot(1, 2, 1);
histogram(L, 'Normalization', 'pdf');
% hist(L, sqrt(length(L)), 'Normalization', 'pdf');
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
xlabel('$L$ [pix]', 'interpreter', 'latex');
ylabel('PDF [-]', 'interpreter', 'latex');
xlim([0, 2*max(L)]);

subplot(1, 2, 2);
boxplot(L);
grid on;
set(gca, 'Units', 'normalized', 'FontUnits', 'points', 'FontWeight', ...
    'normal', 'FontSize', 15, 'FontName','Times');
ylabel('$L$ [pix]', 'interpreter', 'latex');
% ylim([0, 2*max(L)]);
