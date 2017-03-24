#pragma once
#include <opencv2/opencv.hpp>
#include "lsd.h"

int lsd_createLabels(ntuple_list &lsd_out, std::vector<std::pair<int, int>> &lsd_label);
void lsd_detect(cv::Mat &srcImg, ntuple_list &lsd_out);