
#ifndef _HR_EFFECT_BW_H
#define _HR_EFFECT_BW_H





#include "ImageType/ImageType.h"
#include "Utime/GpTime.h"


#include "HrEffectI.h"



class CHrEffectBW : public CHrEffectI
{
public:
	
	CHrEffectBW();

	~CHrEffectBW();

	void DeleteContents();

	int Init();
    int Process( image_type *sim, int iFrame, image_type **im );
	int	Close();

private:
	int m_width;
	int m_height;
	int m_nFrame;
	int	m_iFrame;
	image_type *m_im;
};






#endif


