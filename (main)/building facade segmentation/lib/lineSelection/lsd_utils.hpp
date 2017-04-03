#include <opencv2/opencv.hpp>
//#include "lsd.h"


bool isEqual(const cv::Vec4i& _l1, const cv::Vec4i& _l2)
{
	cv::Vec4i l1(_l1), l2(_l2);

	float length1 = sqrtf((l1[2] - l1[0])*(l1[2] - l1[0]) + (l1[3] - l1[1])*(l1[3] - l1[1]));
	float length2 = sqrtf((l2[2] - l2[0])*(l2[2] - l2[0]) + (l2[3] - l2[1])*(l2[3] - l2[1]));

	float product = (l1[2] - l1[0])*(l2[2] - l2[0]) + (l1[3] - l1[1])*(l2[3] - l2[1]);

	if (fabs(product / (length1 * length2)) < cos(CV_PI / 90))
		return false;

// 	float mx1 = (l1[0] + l1[2]) * 0.5f;
// 	float mx2 = (l2[0] + l2[2]) * 0.5f;
// 
// 	float my1 = (l1[1] + l1[3]) * 0.5f;
// 	float my2 = (l2[1] + l2[3]) * 0.5f;
// 	float dist = sqrtf((mx1 - mx2)*(mx1 - mx2) + (my1 - my2)*(my1 - my2));
// 
// 	if (dist > std::max(length1, length2) * 0.9f)
// 		return false;

	return true;
}

int lsd_createLabels(ntuple_list &lsd_out, std::vector<std::pair<int, int>> &lsd_label)
{
	std::vector<cv::Vec4i> lsd_vec;
	std::vector<int> labels;
	int lsd_dim = lsd_out->dim;
	int no_of_lines = lsd_out->size;
	for (int i = 0; i < no_of_lines; i++)
	{
		cv::Vec4i lsd_tmp;
		lsd_tmp[0] = (int)lsd_out->values[0 + i * lsd_dim];
		lsd_tmp[1] = (int)lsd_out->values[1 + i * lsd_dim];
		lsd_tmp[2] = (int)lsd_out->values[2 + i * lsd_dim];
		lsd_tmp[3] = (int)lsd_out->values[3 + i * lsd_dim];
		lsd_vec.push_back(lsd_tmp);
	}

	// Label out the unique subset ID for each the line segment belings to
	int numberOfLines = cv::partition(lsd_vec, labels, isEqual);
	// Construct a LUT for each line segment w.r.t. its belonging set index.
	for (int i = 0; i < labels.size(); i++)
	{
		std::pair<int, int> freq_count_tmp;
		freq_count_tmp = std::make_pair(labels.at(i), i);
		lsd_label.push_back(freq_count_tmp);

	}
	return numberOfLines;
}

void lsd_detect(cv::Mat &srcImg, ntuple_list &lsd_out)
{
	bool talk = false;
	bool verbose = false;
	// Converting image to image double
	image_double dub_image;
	uint w = srcImg.cols;
	uint h = srcImg.rows;
	uchar* imgP = srcImg.data;

	// All parameters defined here
	//		1.LSD parameters
	double scale = 0.8;       // Scale the image by Gaussian filter to 'scale'.
	double sigma_scale = 0.6; // Sigma for Gaussian filter is computed as sigma = sigma_scale/scale.
	double quant = 2.0;       // Bound to the quantization error on the gradient norm.
	double ang_th = 22.5;     // Gradient angle tolerance in degrees.
	double eps = 0.0;         // Detection threshold, -log10(NFA).
	double density_th = 0.7;  // Minimal density of region points in rectangle.
	int n_bins = 1024;        // Number of bins in pseudo-ordering of gradient modulus.
	double max_grad = 255.0;  // Gradient modulus in the highest bin. The default value corresponds to the highest
							  // gradient modulus on images with gray levels in [0,255].
							  //		2. Other flags and parameters
	double athreshadj = 10;				// Threshold defining whether a pair of lsd are potentially orthogonal.
	float extension_fac = 0.5f;			// Line Extension factor, the larger the number the longer LSD extend.

	dub_image = new_image_double(w, h);
	double px = 0;
	if (talk) std::cout << "\n-----------\nInput data being written to image buffer" << std::endl;
	for (int j = 0; j < (w*h); j++)
	{
		px = imgP[j];
		dub_image->data[j] = px;
		if (verbose)	std::cout << " " << dub_image->data[j];
	}
	lsd_out = LineSegmentDetection(dub_image, scale, sigma_scale, quant, ang_th, eps, density_th, n_bins, max_grad, nullptr);

	free_image_double(dub_image);
}