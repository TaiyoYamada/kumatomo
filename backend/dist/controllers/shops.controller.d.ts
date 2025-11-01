import { Request, Response } from 'express';
export declare function index(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function search(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function show(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function posts(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
export declare function adminCreate(data: any): Promise<{
    id: bigint;
    image_url: string | null;
    created_at: Date;
    updated_at: Date;
    name: string;
    description: string | null;
    address: string | null;
    phone: string | null;
    business_hours: string | null;
    genre: string | null;
    latitude: import("@prisma/client/runtime/library").Decimal | null;
    longitude: import("@prisma/client/runtime/library").Decimal | null;
    has_try_benefit: boolean;
    stamp_count: number;
    is_approved: boolean;
}>;
//# sourceMappingURL=shops.controller.d.ts.map