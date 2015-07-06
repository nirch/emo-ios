
#ifndef _HR_EFFECT_RGBA_H
#define _HR_EFFECT_RGBA_H





#include "ImageType/ImageType.h"
#include "Utime/GpTime.h"


#include "HrEffectI.h"



class CHrEffectRGBA : public CHrEffectI
{
public:
	
	CHrEffectRGBA();

	~CHrEffectRGBA();

	void DeleteContents();

	int Init();
    int Process( image_type *sim, int iFrame, image_type **im );
	int	Close();

private:
    int	m_iFrame;
	image_type *m_im;
};






#endif


