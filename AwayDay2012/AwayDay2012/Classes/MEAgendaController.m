//
//  MEAgendaController.m
//  AwayDay2012
//
//  Created by Meng Yu on 6/18/12.
//  Copyright (c) 2012 ThoughtWorks. All rights reserved.
//

#import "MEAgendaController.h"
#import "MEAgenda.h"
#import "MEAgendaList.h"
#import "MEAgendaLoader.h"
#import "MECalendar.h"
#import "MEColor.h"
#import "MEFavoriteSessionList.h"
#import "MESchedule.h"
#import "MEScheduleCell.h"
#import "MEScheduleExposingController.h"
#import "MESession.h"

#define WINDOW_NAME            @"Awayday 2012"
#define FAVORITE_BUTTON_TITLE  @"Favorite"
#define DONE_BUTTON_TITLE      @"Done"
#define DATA_ARCHIVE_FILE      @"data.archive"
#define AGENDA_FILE_NAME       @"agenda"

@interface MEAgendaController ()

- (BOOL)isValidIndexOfAgendaList:(NSInteger)index;
- (void)exposeSchedule:(MESchedule *)schedule;
- (UIBarButtonItem *)favoriteButton;
- (UIBarButtonItem *)doneButton;
- (void)setCurrentAgendaList:(MEAgendaList *)_agendaList;
- (void)buildAgendaList;
- (void)buildFavoriteSessionList;

- (void)prepareToAddSessionToFavorite;
- (void)confirmAddedFavoriteSession;
- (void)saveFavoriteSessions;
- (void)addFavoriteSessionsToCalendar;

- (NSString *)archivedDataFilePath;

@end

@implementation MEAgendaController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem = [self favoriteButton];
        self.title = WINDOW_NAME;
    }
    return self;
}

- (void)loadView {
    agendaView = [[MEAgendaView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    agendaView.delegate = self;
    
    self.view = agendaView;
}

- (void)viewDidLoad {
    [self buildAgendaList];
    currentAgendaList = [allAgendaList retain];
    [self buildFavoriteSessionList];
    
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)buildAgendaList {
    MEAgendaLoader *agendaLoader = [[MEAgendaLoader alloc] init];
    allAgendaList = [[agendaLoader loadFromFile:AGENDA_FILE_NAME] retain];
    [agendaLoader release];
}

- (UIBarButtonItem *)favoriteButton {
    if (!favoriteButton) {
        favoriteButton = [[UIBarButtonItem alloc] initWithTitle:FAVORITE_BUTTON_TITLE
                                                          style:UIBarButtonItemStylePlain
                                                         target:self 
                                                         action:@selector(prepareToAddSessionToFavorite)];
    }
    return favoriteButton;
}

- (UIBarButtonItem *)doneButton {
    if (!doneButton) {
        doneButton = [[UIBarButtonItem alloc] initWithTitle:DONE_BUTTON_TITLE
                                                      style:UIBarButtonItemStylePlain
                                                     target:self 
                                                     action:@selector(confirmAddedFavoriteSession)];
        doneButton.tintColor = UIColorFromRGB(0xC84131);
    }
    return doneButton;
}

- (void)setCurrentAgendaList:(MEAgendaList *)_agendaList {
    if (self->currentAgendaList == _agendaList) {
        return;
    }
    
    [self->currentAgendaList release];
    self->currentAgendaList = [_agendaList retain];
}

- (NSString *)archivedDataFilePath {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    return [docsDir stringByAppendingPathComponent:DATA_ARCHIVE_FILE];
}

- (void)buildFavoriteSessionList {
    NSString *dataFilePath = [self archivedDataFilePath];
    NSFileManager *fileManager =[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:dataFilePath]) {
        favoriteSessionList = [[MEFavoriteSessionList alloc] initWithContentsOfFile:dataFilePath];
    } else {
        favoriteSessionList = [[MEFavoriteSessionList alloc] init];
    }
}

- (void)dealloc {
    [allAgendaList release];
    [currentAgendaList release];
    [agendaView release];
    [favoriteButton release];
    [doneButton release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Delegation for Agenda View

- (NSInteger)numberOfAgenda:(MEAgendaView *)agendaView {
    return currentAgendaList.count;
}

- (NSInteger)agenda:(MEAgendaView *)agendaView scheduleNumInAgenda:(NSInteger)index {
    if (![self isValidIndexOfAgendaList:index]) {
        return 0;
    }
    return [currentAgendaList agendaAtIndex:index].scheduleCount;
}

- (void)agenda:(MEAgendaView *)agendaView cell:(MEScheduleCell *)cell atScheduleIndex:(NSInteger)scheduleIndex inAgenda:(NSInteger)agendaIndex {
    if (![self isValidIndexOfAgendaList:agendaIndex]) {
        return;
    }
    
    MEAgenda *agenda = [currentAgendaList agendaAtIndex:agendaIndex];
    MESchedule *schedule = [agenda scheduleAt:scheduleIndex];
    
    cell.title = schedule.title;
    cell.from = schedule.from;
    cell.to = schedule.to;
    cell.lecturer = [schedule isKindOfClass:[MESession class]] ? ((MESession *)schedule).lecturer : nil;
    [cell setSelected:[favoriteSessionList containsSession:schedule.title on:schedule.scheduledOn] animated:NO];
}

- (MEDate)agenda:(MEAgendaView *)agendaView dateAtIndex:(NSInteger)index {
    if (![self isValidIndexOfAgendaList:index]) {
        return MEDATE_INVALID;
    }
    return [currentAgendaList agendaAtIndex:index].date;
}

- (BOOL)isValidIndexOfAgendaList:(NSInteger)index {
    return index >= 0 && index < currentAgendaList.count;
}

- (void)agenda:(MEAgendaView *)agendaView exposeScheduleAtIndex:(NSInteger)scheduleIndex inAgenda:(NSInteger)agendaIndex {
    if (![self isValidIndexOfAgendaList:agendaIndex]) {
        return;
    }
    
    MEAgenda *agenda = [currentAgendaList agendaAtIndex:agendaIndex];
    MESchedule *schedule = [agenda scheduleAt:scheduleIndex];
    
    [self exposeSchedule:schedule];
}

- (void)exposeSchedule:(MESchedule *)schedule {
    MEScheduleExposingController *controller = [[MEScheduleExposingController alloc] init];
    [controller exposeSchedule:schedule];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)agenda:(MEAgendaView *)agendaView didSelectScheduleAtIndex:(NSInteger)scheduleIndex inAgenda:(NSInteger)agendaIndex {
    MEAgenda *agenda = [currentAgendaList agendaAtIndex:agendaIndex];
    MESchedule *schedule = [agenda scheduleAt:scheduleIndex];

    [self->favoriteSessionList addSession:schedule.title on:schedule.scheduledOn];
}

- (void)agenda:(MEAgendaView *)agendaView didDeselectScheduleAtIndex:(NSInteger)scheduleIndex inAgenda:(NSInteger)agendaIndex {
    MEAgenda *agenda = [currentAgendaList agendaAtIndex:agendaIndex];
    MESchedule *schedule = [agenda scheduleAt:scheduleIndex];
    
    [self->favoriteSessionList removeSession:schedule.title on:schedule.scheduledOn];
}

#pragma mark -
#pragma mark Delegation for Following Schedule Button

- (void)prepareToAddSessionToFavorite {
    self.navigationItem.rightBarButtonItem = [self doneButton];

    [self setCurrentAgendaList:[allAgendaList onlySessionList]];
    [agendaView startToSelectFavoriteSession];
}

- (void)confirmAddedFavoriteSession {
    [self saveFavoriteSessions];
    [self addFavoriteSessionsToCalendar];
    
    self.navigationItem.rightBarButtonItem = [self favoriteButton];
    
    [self setCurrentAgendaList:allAgendaList];
    [agendaView confirmFavoriteSession];
}

- (void)saveFavoriteSessions {
    NSString *dataFilePath = [self archivedDataFilePath];
    [favoriteSessionList writeToFile:dataFilePath];
}

- (void)addFavoriteSessionsToCalendar {
    MECalendar *calendar = [MECalendar shared];
    
    for (NSInteger i = 0; i < currentAgendaList.count; i++) {
        MEAgenda *agenda = [currentAgendaList agendaAtIndex:i];
        for (NSInteger j = 0; j < agenda.scheduleCount; j++) {
            MESchedule *schedule = [agenda scheduleAt:j];
            if (![schedule isKindOfClass:[MESession class]]) {
                continue;
            }
            if (![favoriteSessionList containsSession:schedule.title on:schedule.scheduledOn]) {
                continue;
            }
            [calendar addSessionEvent:(MESession *)schedule];
        }
    }
}

@end
