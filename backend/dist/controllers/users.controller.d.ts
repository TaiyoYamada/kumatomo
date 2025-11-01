import { Request, Response } from 'express';
export declare function me(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function show(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function update(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function destroy(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function checkUsernameAvailability(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function updateUsername(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function store(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function uploadProfileImage(_req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function uploadCoverImage(_req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
//# sourceMappingURL=users.controller.d.ts.map