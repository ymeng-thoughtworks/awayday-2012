//
//  MEAgendaController.h
//  AwayDay2012
//
//  Created by Meng Yu on 6/18/12.
//  Copyright (c) 2012 ThoughtWorks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MEAgendaView.h"

@class MEAgendaList, MEFavoriteSessionList;

@interface MEAgendaController : UIViewController <MEAgendaDelegate> {
    MEAgendaList *allAgendaList;
    MEAgendaList *currentAgendaList;
    MEFavoriteSessionList *favoriteSessionList;
    MEAgendaView *agendaView;
    
    UIBarButtonItem *favoriteButton, *doneButton;
}

@end
