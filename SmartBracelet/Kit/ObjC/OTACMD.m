//
//  Bluetooth.m
//  OTA-2-16-OC
//
//  Created by Arvin on 2017/2/16.
//  Copyright © 2017年 Arvin. All rights reserved.
//

#import "OTACMD.h"
@interface OTACMD ()
@property (assign, nonatomic) int count;

@end
@implementation OTACMD
@synthesize delegate;

- (void)versionGet {
    uint8_t buf[2] = {0x00,0xff};
    NSData *data = [NSData dataWithBytes:buf length:2];
    [delegate writeOTAData:data];
}
- (void)startOTA {
    uint8_t buf[2] = {0x01,0xff};
    NSData *data = [NSData dataWithBytes:buf length:2];
    [delegate writeOTAData:data];
    NSLog(@"startOTA data - > %@", data);
}
- (void)endOTA {
    uint8_t buf[6] = {0x02,0xff,0,0,0,0};
    buf[2] = (self.otaPackIndex-1)&0xff;
    buf[3] = ((self.otaPackIndex-1) >>8)& 0xff;
    buf[4] = (~(self.otaPackIndex-1))&0xff;
    buf[5] = ((~(self.otaPackIndex-1))>>8)&0xff;
    uint8_t verifyB[8];
    memset(verifyB, 0, 8);
    for (int j=0; j<6; j++) {
        verifyB[j] = buf[j];
    }
    //CRC
    unsigned short crc_t = crc16(buf, 6);
    verifyB[6] = (crc_t)&0xff;
    verifyB[7] = (crc_t >> 8) & 0xff;
    NSData *data = [NSData dataWithBytes:verifyB length:8];
    [delegate writeOTAData:data];
    NSLog(@"end OTA data - > %@", data);
}

- (void)sendOTAPackData:(NSData *)data {
    NSUInteger length = data.length;
    uint8_t *tempData=(uint8_t *)[data bytes];
    uint8_t pack_head[2];
    pack_head[1] = (self.otaPackIndex >>8)& 0xff;
    pack_head[0] = (self.otaPackIndex)&0xff;
    
    //data
    if (length > 0 && length < 16) {
        length = 16;
    }
    uint8_t otaBuffer[length+4];
    memset(otaBuffer, 0, length+4);
    
    
    uint8_t otaCmd[length+2];
    memset(otaCmd, 0, length+2);
    
    for (int i = 0; i < 2; i ++) {       //index指数部分
        otaBuffer[i] = pack_head[i];
    }
    for (int i = 2; i < length+2; i++) {  //bin 文件数据包
        if (i < data.length+2) {
            otaBuffer[i] = tempData[i-2];
        }else{
            otaBuffer[i] = 0xff;
        }
    }
    for (int i = 0; i < length+2; i++) {
        otaCmd[i] = otaBuffer[i];
    }
    
    //CRC
    unsigned short crc_t = crc16(otaCmd, (int)length+2);
    uint8_t crc[2];
    crc[1] = (crc_t >> 8) & 0xff;
    crc[0] = (crc_t)&0xff;
    for (int i = (int)length+3; i > (int)length+1; i--) {   //2->4
        otaBuffer[i] = crc[i-length-2];
    }

    NSData *tempdata=[NSData dataWithBytes:otaBuffer length:length+4];
    [delegate writeOTAData:tempdata];
    if (length == 0)
        self.otaPackIndex = NSNotFound;
}

- (void)readOTA {
    [delegate readOTA];
}

extern unsigned short crc16 (unsigned char *pD, int len) {
    static unsigned short poly[2]={0, 0xa001};              //0x8005 <==> 0xa001
    unsigned short crc = 0xffff;
    int i,j;
    for(j=len; j>0; j--) {
        unsigned char ds = *pD++;
        for(i=0; i<8; i++) {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
    }
    return crc;
}

- (void)printCommand:(uint8_t *)cmd len:(NSInteger)len str:(NSString *)str {
    NSMutableArray *temp = [NSMutableArray array];
    for (NSInteger i=0; i<len; i++) {
        [temp addObject:[NSString stringWithFormat:@"%x",cmd[i]]];
    }
}

@end
