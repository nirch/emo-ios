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

#include "HrEffectRGBA.h"

CHrEffectRGBA::CHrEffectRGBA()
{
	m_im = NULL;
}

CHrEffectRGBA::~CHrEffectRGBA()
{
	DeleteContents();
}


void CHrEffectRGBA::DeleteContents()
{
	if( m_im != NULL ){
		image_destroy( m_im, 1 );
		m_im = NULL;
	}
}

int CHrEffectRGBA::Init()
{
	m_iFrame = -1;
	return( 1 );
}


int	CHrEffectRGBA::Process( image_type *sim, int iFrame, image_type **im )
{
    // TODO: implement.
    return( 1 );
}

int	CHrEffectRGBA::Close()
{
    DeleteContents();
    return( 1 );
}


