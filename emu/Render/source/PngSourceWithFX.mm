//
//  PngSourceWithFX.h
//

#import "PngSourceWithFX.h"
#import <UIKit/UIKit.h>
#import "Gpw/Vtool/Vtool.h"

PngSourceWithFX::PngSourceWithFX(NSArray *pngFiles)
{
    m_pngFiles = pngFiles;
}

int	PngSourceWithFX::ReadFrame( int iFrame, image_type **im )
{
    if (iFrame < m_pngFiles.count)
    {
        NSString *imagePath = [m_pngFiles objectAtIndex:iFrame];
        UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
        *im = CVtool::UIimage_to_image(image, *im);
        MergeAlpha(*im);
        return 1;
    }
    else
    {
        // index out of bounds
        return -1;
    }
}

int PngSourceWithFX::Close()
{
    return 1;
}