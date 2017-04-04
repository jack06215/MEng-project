#include <opencv2/opencv.hpp>
#include "mex.h"
#include "opencv_matlab.hpp"

// Here the order is important!!...
#include "lsd.hpp"
#include "lsd_utils.hpp"

void 
mexFunction(int nlhs, mxArray *plhs[], 
            int nrhs, const mxArray *prhs[])
{
    //validate input
    if (nrhs == 0)
    {
        mexErrMsgTxt("An image is required!");
    }
    if(!mxIsDouble(prhs[0]) || ((mxGetNumberOfDimensions(prhs[0]) != 3) && (mxGetNumberOfDimensions(prhs[0]) != 2)))
    {
        mexErrMsgTxt("Type of the image has to be double.");
    }
    
    // determine input image properties
    const int *dims    = mxGetDimensions(prhs[0]);
    const int nDims    = mxGetNumberOfDimensions(prhs[0]);
    const int rows     = dims[0];
    const int cols     = dims[1];
    const int channels = (nDims == 3 ? dims[2] : 1);
    
    
    // Allocate, copy, and convert the input image
    // @note: input is double
    cv::Mat image = cv::Mat::zeros(cv::Size(cols, rows), CV_64FC(channels));
    cv::Mat out;
    cv::Mat image_gray;
    
    // Copy MATLAB image to OpenCV Mat structure, it needs to be double type
    om::copyMatrixToOpencv(mxGetPr(prhs[0]), image);
    image.convertTo(image, CV_8U, 255);
    ntuple_list lsd_out;
    lsd_out = new_ntuple_list(5);
    
    double *A_ptr = NULL;
    A_ptr = mxGetPr(prhs[1]);
    const int *A_dims    = mxGetDimensions(prhs[1]);
    const int A_size = A_dims[1];
    for (int i=0; i < A_size; i++)
    {
        struct rect
			{
				double x1, y1, x2, y2; /* first and second point of the line segment */
				double width;        /* rectangle width */
			} rec;
            rec.x1 = *A_ptr++;
			rec.y1 = *A_ptr++;
			rec.x2 = *A_ptr++;
			rec.y2 = *A_ptr++;
			rec.width = 2;
			add_5tuple(lsd_out, rec.x1, rec.y1, rec.x2, rec.y2, rec.width);
    }
    
    

/////////// ***** Do the magic stuff in OpenCV C++ here!! ***** ///////////
    std::vector<std::pair<int, int>> lsd_label; // [label ID, lsd ID]
    
    image.copyTo(out);
    image.copyTo(image_gray);
    
    // 3rd party line segment detection
    
    ntuple_list lsd_selected;
    //lsd_detect(image_gray, lsd_out);
    
    
    
    
    
    
    int numnerOfLines = lsd_createLabels(lsd_out, lsd_label);
    
    int no_of_lines = lsd_out->size;
    const unsigned int lsd_dim = lsd_out->dim;
    
//     // Draw the result to output image
//     for (int i = 0; i < no_of_lines; i++)
//     {
//         cv::Point pt1, pt2;
//         pt1.x = (int)lsd_out->values[0 + i * lsd_dim];
//         pt1.y = (int)lsd_out->values[1 + i * lsd_dim];
//         pt2.x = (int)lsd_out->values[2 + i * lsd_dim];
//         pt2.y = (int)lsd_out->values[3 + i * lsd_dim];
//         // The 5th element is the width of line segment
//         int line_width = 2;
//         cv::line(out, pt1, pt2, cv::Scalar(0, 255, 255), line_width, CV_AA);
//     }
    std::sort(lsd_label.begin(), lsd_label.end());
    // Select dominant line segments
    lsd_selected = new_ntuple_list(5);
    
    std::vector<int> lsd_selected_idx;
	std::vector<std::pair<int, std::vector<int>>> lsd_label_table;
	int current = lsd_label.at(0).first;
	std::vector<int> freq_sorted;
	std::pair<int, std::vector<int>> freq_pushed;
	std::vector<std::pair<int, int>> freq_count;
	int set_idx = 0;
	for (int i = 0; i < lsd_label.size() - 1; i++)
	{
		freq_sorted.push_back(lsd_label.at(i).second);
		current = lsd_label.at(i).first;
		if (current != lsd_label.at(i + 1).first)
		{
			freq_pushed.first = set_idx;
			freq_pushed.second.swap(freq_sorted);
			lsd_label_table.push_back(freq_pushed);
			freq_sorted.clear();
			set_idx++;
		}
	}
    
    	for (int i = 0; i < lsd_label_table.size(); i++)
	{
		std::pair<int, int> tmp = std::make_pair(lsd_label_table.at(i).second.size(), lsd_label_table.at(i).first);
		freq_count.push_back(tmp);
	}
	std::sort(freq_count.rbegin(), freq_count.rend());
    

	// Select the most dominant line segment: pick the most the the second most dominant inedex.
	bool isDone = false;
	lsd_selected_idx.push_back(freq_count.at(0).second);
	lsd_selected_idx.push_back(freq_count.at(1).second);
//     lsd_selected_idx.push_back(freq_count.at(2).second);
//     lsd_selected_idx.push_back(freq_count.at(3).second);
    
    	for (int i = 0; i < lsd_selected_idx.size(); i++)
	{
		int idxx = lsd_selected_idx.at(i);
		for (int j = 0; j < lsd_label_table.at(idxx).second.size(); j++)
		{
			int idx = lsd_label_table.at(idxx).second.at(j);
			struct rect
			{
				double x1, y1, x2, y2; /* first and second point of the line segment */
				double width;        /* rectangle width */
			} rec;
			rec.x1 = lsd_out->values[0 + idx * lsd_dim];
			rec.y1 = lsd_out->values[1 + idx * lsd_dim];
			rec.x2 = lsd_out->values[2 + idx * lsd_dim];
			rec.y2 = lsd_out->values[3 + idx * lsd_dim];
			rec.width = lsd_out->values[4 + idx * lsd_dim];
			add_5tuple(lsd_selected, rec.x1, rec.y1, rec.x2, rec.y2, rec.width);
		}
	}
    
////////////////// ***** End of OpenCV C++ !! ***** //////////////////
    
    

    
    // retrive and copy the lsd_detect information to MATLAB array
	double *D_ptr = NULL;
	plhs[1] = mxCreateDoubleMatrix(4, no_of_lines, mxREAL); // 4 x num_lines
	D_ptr = mxGetPr(plhs[1]);
	for (int i = 0; i < no_of_lines; i++)
	{
		*D_ptr++ = (double)lsd_out->values[0 + i * lsd_dim]; // x1
		*D_ptr++ = (double)lsd_out->values[1 + i * lsd_dim]; // y1
		*D_ptr++ = (double)lsd_out->values[2 + i * lsd_dim]; // x2
		*D_ptr++ = (double)lsd_out->values[3 + i * lsd_dim]; // y2
	}
    
    double *M_ptr = NULL;
    plhs[2] = mxCreateDoubleMatrix(2, lsd_label.size(), mxREAL);
    M_ptr = mxGetPr(plhs[2]);
    for (int i = 0; i < lsd_label.size(); i++)
	{
		*M_ptr++ = (double)lsd_label.at(i).first;   // Label Index
		*M_ptr++ = (double)lsd_label.at(i).second;  // lsd Index
	}
    
    no_of_lines = lsd_selected->size;
    double *E_ptr = NULL;
 	plhs[3] = mxCreateDoubleMatrix(4, no_of_lines, mxREAL); // 4 x num_lines
 	E_ptr = mxGetPr(plhs[3]);
    //*E_ptr++ = (double)lsd_selected->size;
	for (int i = 0; i < no_of_lines; i++)
	{
		*E_ptr++ = (double)lsd_selected->values[0 + i * lsd_dim]; // x1
		*E_ptr++ = (double)lsd_selected->values[1 + i * lsd_dim]; // y1
		*E_ptr++ = (double)lsd_selected->values[2 + i * lsd_dim]; // x2
		*E_ptr++ = (double)lsd_selected->values[3 + i * lsd_dim]; // y2
	}

    
    // Draw the result to output image
    for (int i = 0; i < no_of_lines; i++)
    {
        cv::Point pt1, pt2;
        pt1.x = (int)lsd_selected->values[0 + i * lsd_dim];
        pt1.y = (int)lsd_selected->values[1 + i * lsd_dim];
        pt2.x = (int)lsd_selected->values[2 + i * lsd_dim];
        pt2.y = (int)lsd_selected->values[3 + i * lsd_dim];
        // The 5th element is the width of line segment
        int line_width = 2;
        cv::line(out, pt1, pt2, cv::Scalar(0, 255, 255), line_width, CV_AA);
    }
    
    // Convert opencv to Matlab and set as output
    plhs[0] = mxCreateNumericArray(nDims, dims, mxUINT8_CLASS, mxREAL);
    om::copyMatrixToMatlab<unsigned char>(out, (unsigned char*)mxGetPr(plhs[0]));
    
    // recycle memory
    free_ntuple_list(lsd_out);
    free_ntuple_list(lsd_selected);
}