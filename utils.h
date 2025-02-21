#ifndef UTILS_H
#define UTILS_H

#include <opencv2/opencv.hpp>

#ifdef _WIN32
#include <windows.h>
#else
#include <dirent.h>
#endif

static inline int read_files_in_dir(const char* p_dir_name, std::vector<std::string>& file_names)
{
#ifdef _WIN32
    // Windows平台的文件目录读取
    WIN32_FIND_DATA findFileData;
    HANDLE hFind = FindFirstFile(std::string(std::string(p_dir_name) + "\\*").c_str(), &findFileData);
    
    if (hFind == INVALID_HANDLE_VALUE) {
        return -1;
    }

    do {
        if (strcmp(findFileData.cFileName, ".") != 0 && strcmp(findFileData.cFileName, "..") != 0) {
            file_names.push_back(findFileData.cFileName);
        }
    } while (FindNextFile(hFind, &findFileData) != 0);
    
    FindClose(hFind);
#else
    // Linux平台的文件目录读取
    DIR *p_dir = opendir(p_dir_name);
    if (p_dir == nullptr) {
        return -1;
    }

    struct dirent* p_file = nullptr;
    while ((p_file = readdir(p_dir)) != nullptr) {
        if (strcmp(p_file->d_name, ".") != 0 &&
            strcmp(p_file->d_name, "..") != 0) {
            std::string cur_file_name(p_file->d_name);
            file_names.push_back(cur_file_name);
        }
    }

    closedir(p_dir);
#endif

    return 0;
}

#endif  // UTILS_H
