//  Defines the entry point for the console application.
//
#include	<string.h>
#include	<math.h>
#include <stdlib.h>

#ifdef _DEBUG
#define _DUMP
#endif

#include "Ulog/Log.h"
#include "ImageType/ImageType.h"
#include "ImageDump/ImageDump.h"

#include "HrEffectBW.h"

image_type *image4_bw( image_type *sim, image_type *im );

CHrEffectBW::CHrEffectBW()
{
	m_im = NULL;
}

CHrEffectBW::~CHrEffectBW()
{
	DeleteContents();
}


void CHrEffectBW::DeleteContents()
{
	if( m_im != NULL ){
		image_destroy( m_im, 1 );
		m_im = NULL;
	}
}

int CHrEffectBW::Init()
{
	m_iFrame = -1;
	return( 1 );
}


int	CHrEffectBW::Process( image_type *sim, int iFrame, image_type **im )
{
    m_iFrame = iFrame;
    m_im = image4_bw(sim, m_im);
    *im = m_im;
	return( 1 );
}

int	CHrEffectBW::Close()
{
    DeleteContents();
    return( 1 );
}

image_type *image4_bw( image_type *sim, image_type *im )
{
    int	i,	j;
    im = image_realloc( im, sim->width, sim->height, 4, IMAGE_TYPE_U8, 1  );
    
    u_char *tp = im->data;
    u_char *sp = sim->data;
    for( i = 0 ; i < im->row ; i++ )
        for( j = 0 ; j < im->column ; j++, sp += 4, tp += 4 ){
            // Get the channels.
            u_char b = sp[0];
            u_char g = sp[1];
            u_char r = sp[2];
            u_char a = sp[3];
            
            // Set to gray value.
            u_char gray = u_char(float(r)*0.2989f+float(g)*0.587f+float(b)*0.114f);
            tp[0] = gray;
            tp[1] = gray;
            tp[2] = gray;
            tp[3] = a;
        }
    
    return( im );
}
