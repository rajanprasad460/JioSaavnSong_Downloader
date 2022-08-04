clc;
clear;

%% Description
%% This module will download songs from the Giosaavan website either specified by the
%% ALBUM Name or ARTIST Name
%% o_search_text is either the album name or the artist name

%% User Input section
% o_search_text = 'Kaho Naa Pyar Hai';
% o_search_text = 'Mangal Bhavan Amangal Hari';
% o_search_text = 'Jai Jai Shri Ram';
% o_search_text = 'Uttar Ramayan';
% o_search_text = 'Kavita Krishnamurti Subramaniam Songs';
% o_search_text = 'Ravindra Jain Songs';
% o_search_text = 'Ishq (Original Motion Picture Soundtrack)';
% o_search_text = 'Guru';
o_search_text = 'tere bina';
% o_search_text = 'rait zara si';


% o_search_type = 'ALBUM';
% o_search_type = 'ARTIST';
o_search_type = 'SONG';
%%  Actual progress section
searchtext = strrep(o_search_text,' ','+');

if strcmp(o_search_type,'ALBUM')
    url_m = strcat('https://www.jiosaavn.com/api.php?p=1&q=',searchtext,'&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=20&__call=search.getAlbumResults');
elseif strcmp(o_search_type,'ARTIST')
    url_m = strcat('https://www.jiosaavn.com/api.php?p=1&q=',searchtext,'&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=20&__call=search.getArtistResults');
elseif strcmp(o_search_type,'SONG')
    url_m = strcat('https://www.jiosaavn.com/api.php?p=1&q=',searchtext,'&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=20&__call=search.getResults');
else
    warning('Specify type of result required');
end

%% Read the details of the specified search
mypage_m = webread(url_m);
mydata_m = jsondecode(mypage_m);

%% In case if it is song , ask user to select the best possible search
if strcmp(o_search_type,'SONG')
    t_string = {'title','subtitle'};
    clc;
    A = fieldnames(mydata_m.results);
    A = A(~contains(A,t_string));
    B = rmfield(mydata_m.results,A);
    fprintf ('\n %d results found for searched keywords \n',length(mydata_m.results));
    T =  struct2table(B);
    T.Properties.RowNames = string(strcat(repmat('A',length(mydata_m.results),1),num2str([1:length(mydata_m.results)]')));
    disp(T);
    key = input(['\n Please enter song index [1,2,3,...] to be downloaded',':']);

    mydata_m.results =  mydata_m.results(key);
    %% ask user if he/she only want to download that song or all from the album
    user_choice = input(['\n Do you want to download all song of the containing album [1 for Yes/ 0 for No]',':']);
    if user_choice == 1
        % Do the work
        o_search_text = mydata_m.results.more_info.album;
        searchtext = strrep(o_search_text,' ','+');
        o_search_type = 'ALBUM';
    end
end


%% Extract the result and work on it
for i = 1:length(mydata_m.results)
    if contains(o_search_type,{'ALBUM','ARTIST'})
        if user_choice == 0
            if contains(mydata_m.results(i).title,o_search_text)
                %% Downloader in action
                Downloader(mydata_m,i,o_search_type,user_choice);
            end
        else
            %% Downloader in action
            Downloader(mydata_m,i,o_search_type,user_choice);
        end
    end
    if strcmp(o_search_type,'SONG')
        %% Downloader in action
        %         c_folder = strcat(cd,'\',strrep(mydata_m.results(i).title,' ','_'));
        %% If the folder doesn't exist, create it
        %         if ~exist(c_folder,"dir")
        %             mkdir(c_folder)
        %         end


        c_folder = cd;
        tokens_1 =  strsplit(mydata_m.results.more_info.album_url,'/');
        tokens_1 = tokens_1{1,end};
        %====== Url to specific album/artist  ========================
        if strcmp(o_search_type,'ALBUM')
            url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=album');
        end
        if strcmp(o_search_type,'ARTIST')
            url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=artist');
        end
        if strcmp(o_search_type,'SONG')
            url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=album');
        end
        %% ======= Read all the songs of specific album/artist ==================
        mypage = webread(url);
        mydata = jsondecode(mypage);
        %% ============ Download all songs of the specific album/artist if allowed ======

        for j1 =1:length(mydata.list)
            %% Find the position of song in album
            if strcmp(mydata_m.results.title,mydata.list(j1).title)
                j = j1;
            end
        end
        % Identifying the encrypted media url
        u_id = urlencoder(mydata.list(j).more_info.encrypted_media_url)  ;
        if length(string(u_id)) ==1
            %=========== Downloading authorized download link for that
            %encrypted url and saving as txt file
            down_url = strcat('curl "https://www.jiosaavn.com/api.php?__call=song.generateAuthToken&url=',u_id,'&bitrate=128&api_version=4&_format=json&ctx=web6dot0&_marker=0">"',c_folder,'\temp_url.txt"');
            system(down_url);
            %% Reading the downloaded file
            fileID = fopen(strcat(c_folder,'\temp_url.txt'),'r');
            formatSpec = '%s';
            auth_url_text = fscanf(fileID,formatSpec);
            fclose(fileID);
            delete(strcat(c_folder,'\temp_url.txt'));
            %% Correcting the link to find actual download link and downloading it==
            add_url = string(extractBetween(auth_url_text,'.com','?'));
            add_url = strrep(add_url,'\','');
            if ~isempty(add_url)

                try
                    filename = strcat(c_folder,'\',strrep(mydata_m.results.title,' ','_'),'.mp3');
                    if ~isfile(filename)
                        url_d = strcat('curl "https://sklktecdnems02.cdnsrv.jio.com/jiosaavn.cdn.jio.com/',add_url,'">"',c_folder,'\',strrep(mydata_m.results.title,' ','_'),'.mp3" & exit &');
                        system(url_d);
                    end
                catch
                    filename = strcat(c_folder,'\',matlab.lang.makeValidName(mydata_m.results.title),'.mp3');
                    if ~isfile(filename)
                        url_d = strcat('curl "https://sklktecdnems02.cdnsrv.jio.com/jiosaavn.cdn.jio.com/',add_url,'">"',c_folder,'\',matlab.lang.makeValidName(mydata_m.results.title),'.mp3" & exit &');
                        system(url_d);
                    end
                end

            end
        end
        progressupdater(1,length(mydata_m.results),sprintf('Downloading Songs [%d]',i));
    end
end



function Downloader(mydata_m,i,o_search_type,user_choice)

if user_choice == 1
    c_folder = strcat(cd,'\',strrep(mydata_m.results(i).more_info.album,' ','_'));
else
    c_folder = strcat(cd,'\',strrep(mydata_m.results(i).title,' ','_'));
end
%% If the folder doesn't exist, create it
if ~exist(c_folder,"dir")
    mkdir(c_folder)
end

if user_choice == 1
    tokens_1 =  strsplit(mydata_m.results(i).more_info.album_url,'/');
else
    tokens_1 =  strsplit(mydata_m.results(i).perma_url,'/');
end

tokens_1 = tokens_1{1,end};
%====== Url to specific album/artist  ========================
if strcmp(o_search_type,'ALBUM')
    url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=album');
end
if strcmp(o_search_type,'ARTIST')
    url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=artist');
end
if strcmp(o_search_type,'SONG')
    url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=album');
end
%% ======= Read all the songs of specific album/artist ==================
mypage = webread(url);
mydata = jsondecode(mypage);
if user_choice == 1
    mydata_m.results = mydata.list;
end
%% ============ Download all songs of the specific album/artist if allowed ======
for j =1:length(mydata.list)
    % Identifying the encrypted media url
    u_id = urlencoder(mydata.list(j).more_info.encrypted_media_url)  ;
    if length(string(u_id)) ==1
        %=========== Downloading authorized download link for that
        %encrypted url and saving as txt file
        down_url = strcat('curl "https://www.jiosaavn.com/api.php?__call=song.generateAuthToken&url=',u_id,'&bitrate=128&api_version=4&_format=json&ctx=web6dot0&_marker=0">"',c_folder,'\temp_url.txt"');
        system(down_url);
        %% Reading the downloaded file
        fileID = fopen(strcat(c_folder,'\temp_url.txt'),'r');
        formatSpec = '%s';
        auth_url_text = fscanf(fileID,formatSpec);
        fclose(fileID);
        delete(strcat(c_folder,'\temp_url.txt'));
        %% Correcting the link to find actual download link and downloading it==
        add_url = string(extractBetween(auth_url_text,'.com','?'));
        add_url = strrep(add_url,'\','');
        if ~isempty(add_url)

            try
                filename = strcat(c_folder,'\',strrep(mydata_m.results(j).title,' ','_'),'.mp3');
                if ~isfile(filename)
                    url_d = strcat('curl "https://sklktecdnems02.cdnsrv.jio.com/jiosaavn.cdn.jio.com/',add_url,'">"',c_folder,'\',strrep(mydata_m.results(j).title,' ','_'),'.mp3" & exit &');
                    system(url_d);
                end
            catch
                filename = strcat(c_folder,'\',matlab.lang.makeValidName(mydata_m.results(j).title),'.mp3');
                if ~isfile(filename)
                    url_d = strcat('curl "https://sklktecdnems02.cdnsrv.jio.com/jiosaavn.cdn.jio.com/',add_url,'">"',c_folder,'\',matlab.lang.makeValidName(mydata_m.results(j).title),'.mp3" & exit &');
                    system(url_d);
                end
            end

        end
    end
    if strcmp(o_search_type,'ALBUM')
        progressupdater(j,length(mydata.list),sprintf('Downloading Songs [%d/%d]',i,length(mydata_m.results)));
    else
        progressupdater(j,length(mydata.list),sprintf('Downloading Songs [%d]',i));
    end
end
end