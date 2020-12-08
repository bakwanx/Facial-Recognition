function varargout = facial_recognition(varargin)
% FACIAL_RECOGNITION MATLAB code for facial_recognition.fig
%      FACIAL_RECOGNITION, by itself, creates a new FACIAL_RECOGNITION or raises the existing
%      singleton*.
%
%      H = FACIAL_RECOGNITION returns the handle to a new FACIAL_RECOGNITION or the handle to
%      the existing singleton*.
%
%      FACIAL_RECOGNITION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FACIAL_RECOGNITION.M with the given input arguments.
%
%      FACIAL_RECOGNITION('Property','Value',...) creates a new FACIAL_RECOGNITION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before facial_recognition_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to facial_recognition_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help facial_recognition

% Last Modified by GUIDE v2.5 01-Dec-2020 14:52:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @facial_recognition_OpeningFcn, ...
                   'gui_OutputFcn',  @facial_recognition_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before facial_recognition is made visible.
function facial_recognition_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to facial_recognition (see VARARGIN)

% Choose default command line output for facial_recognition
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes facial_recognition wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = facial_recognition_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[name_file1,name_path1] = uigetfile( ...
    {'*.bmp;*.jpg;*.tif','Files of type (*.bmp,*.jpg,*.tif)';
    '*.bmp','File Bitmap (*.bmp)';...
    '*.jpg','File jpeg (*.jpg)';
    '*.tif','File Tif (*.tif)';
    '*.*','All Files (*.*)'},...
    'Open Image');
 
if ~isequal(name_file1,0)
    handles.data1 = imread(fullfile(name_path1,name_file1));
    guidata(hObject,handles);
    axes(handles.axes1);
    imshow(handles.data1);
else
    return;
end 

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
img = handles.data1;

%outputfolder = fullfile('dataset');
rootfolder = fullfile('dataset');
categories = {'bella','farhan','rozan','dimas','maudy','yabes','dita'};%deklarasi categories
imds = imageDatastore(fullfile(rootfolder, categories), 'LabelSource', 'foldernames');%membuat categori dari nama folder

tbl = countEachLabel(imds);%menghitung file foto setiap folder dalam bentuk tabel


bella = find(imds.Labels == 'bella', 1);
farhan = find(imds.Labels == 'farhan', 1);
rozan = find(imds.Labels == 'rozan', 1);
dimas = find(imds.Labels == 'dimas', 1);
maudy = find(imds.Labels == 'maudy', 1);
yabes = find(imds.Labels == 'yabes', 1);
dita = find(imds.Labels == 'dita', 1);


net = resnet50();%panggil fungsi resnet, tapi sebelumnya download dan install terlebih dahulu package resnet-50 di add ons


display(net.Layers(1)); %inspect properti input layer
display(net.Layers(end)); %inspect properti layer terakhir'
display(numel(net.Layers(end).ClassNames)); % menghitung banyak class dalam network
[trainingSet, testSet] = splitEachLabel(imds, 0.3, 'randomize'); %menggunakan 30% data untuk training, dan 70%untuk validation dan dipilih secara acak

imageSize = net.Layers(1).InputSize; %ukuran yang ditentukan untuk ResNet50 
augmentedTrainingSet = augmentedImageDatastore(imageSize, ...
    trainingSet, 'ColorPreprocessing','gray2rgb');
augmentedTestSet = augmentedImageDatastore(imageSize, ...
    testSet, 'ColorPreprocessing','gray2rgb');

w1 = net.Layers(2).Weights;
w1 = mat2gray(w1);

featureLayer = 'fc1000';
trainingFeatures = activations(net,...
    augmentedTrainingSet, featureLayer, 'MiniBatchSize', 32, 'OutputAs', 'columns');

trainingLables = trainingSet.Labels;
classifier = fitcecoc(trainingFeatures, trainingLables,...
    'Learner', 'Linear', 'Coding', 'onevsall', 'ObservationsIn', 'columns');
testFeatures = activations(net,...
    augmentedTestSet, featureLayer, 'MiniBatchSize', 32, 'OutputAs', 'columns');

predictLabels = predict(classifier, testFeatures, 'ObservationsIn', 'columns'); %prediksi labels

testLables = testSet.Labels;%actual labels
confMat = confusionmat(testLables, predictLabels);%confusion matriks
confMat = bsxfun(@rdivide, confMat, sum(confMat,2));

mean(diag(confMat));

%memasukkan image yang ingin di klasifikasikan
ds = augmentedImageDatastore(imageSize, ...
    img, 'ColorPreprocessing','gray2rgb');

imageFeature = activations(net,...
    ds, featureLayer, 'MiniBatchSize', 32, 'OutputAs', 'columns');

label = predict(classifier, imageFeature, 'ObservationsIn', 'columns');


set(handles.edit1,'String',label) 


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
