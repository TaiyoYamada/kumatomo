const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';

interface FetchOptions extends RequestInit {
    token?: string;
}

class ApiClient {
    private baseUrl: string;

    constructor(baseUrl: string) {
        this.baseUrl = baseUrl;
    }

    private async request<T>(endpoint: string, options: FetchOptions = {}): Promise<T> {
        const { token, ...fetchOptions } = options;

        const headers: HeadersInit = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...(token && { 'Authorization': `Bearer ${token}` }),
            ...fetchOptions.headers,
        };

        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            ...fetchOptions,
            headers,
        });

        if (!response.ok) {
            const error = await response.json().catch(() => ({ message: 'An error occurred' }));
            throw new ApiError(response.status, error.message || 'Request failed', error);
        }

        return response.json();
    }

    // Auth
    async login(email: string, password: string): Promise<{ access_token: string; user: User }> {
        return this.request('/login', {
            method: 'POST',
            body: JSON.stringify({ email, password }),
        });
    }

    // Admin endpoints - require token
    async getUsers(token: string, params?: UserQueryParams): Promise<PaginatedResponse<User>> {
        const query = params ? `?${new URLSearchParams(params as Record<string, string>)}` : '';
        return this.request(`/admin/users${query}`, { token });
    }

    async getUser(token: string, id: number): Promise<User> {
        return this.request(`/admin/users/${id}`, { token });
    }

    async updateUser(token: string, id: number, data: Partial<User>): Promise<User> {
        return this.request(`/admin/users/${id}`, {
            method: 'PUT',
            token,
            body: JSON.stringify(data),
        });
    }

    async deleteUser(token: string, id: number): Promise<{ message: string }> {
        return this.request(`/admin/users/${id}`, { method: 'DELETE', token });
    }

    async getUserStats(token: string): Promise<UserStats> {
        return this.request('/admin/stats/users', { token });
    }

    async getPosts(token: string, params?: PostQueryParams): Promise<PaginatedResponse<Post>> {
        const query = params ? `?${new URLSearchParams(params as Record<string, string>)}` : '';
        return this.request(`/admin/posts${query}`, { token });
    }

    async getPost(token: string, id: number): Promise<Post> {
        return this.request(`/admin/posts/${id}`, { token });
    }

    async deletePost(token: string, id: number): Promise<{ message: string }> {
        return this.request(`/admin/posts/${id}`, { method: 'DELETE', token });
    }

    async getPostStats(token: string): Promise<PostStats> {
        return this.request('/admin/stats/posts', { token });
    }

    async getPortalSlides(token: string): Promise<PortalSlide[]> {
        return this.request('/admin/portal-slides', { token });
    }

    async createPortalSlide(token: string, data: Omit<PortalSlide, 'id'>): Promise<PortalSlide> {
        return this.request('/admin/portal-slides', {
            method: 'POST',
            token,
            body: JSON.stringify(data),
        });
    }

    async updatePortalSlide(token: string, id: number, data: Partial<PortalSlide>): Promise<PortalSlide> {
        return this.request(`/admin/portal-slides/${id}`, {
            method: 'PUT',
            token,
            body: JSON.stringify(data),
        });
    }

    async deletePortalSlide(token: string, id: number): Promise<{ message: string }> {
        return this.request(`/admin/portal-slides/${id}`, { method: 'DELETE', token });
    }

    async reorderPortalSlides(token: string, order: number[]): Promise<{ message: string }> {
        return this.request('/admin/portal-slides/reorder', {
            method: 'POST',
            token,
            body: JSON.stringify({ order }),
        });
    }

    // Announcements
    async getAnnouncements(token: string, params?: { page?: number; per_page?: number; search?: string }): Promise<PaginatedResponse<Announcement>> {
        const query = params ? `?${new URLSearchParams(params as Record<string, any>)}` : '';
        return this.request(`/admin/announcements${query}`, { token });
    }

    async createAnnouncement(token: string, data: Omit<Announcement, 'id' | 'created_at' | 'updated_at'>): Promise<Announcement> {
        return this.request('/admin/announcements', {
            method: 'POST',
            token,
            body: JSON.stringify(data),
        });
    }

    async updateAnnouncement(token: string, id: number, data: Partial<Announcement>): Promise<Announcement> {
        return this.request(`/admin/announcements/${id}`, {
            method: 'PUT',
            token,
            body: JSON.stringify(data),
        });
    }

    async deleteAnnouncement(token: string, id: number): Promise<{ message: string }> {
        return this.request(`/admin/announcements/${id}`, { method: 'DELETE', token });
    }
}

export class ApiError extends Error {
    constructor(
        public status: number,
        message: string,
        public data?: unknown
    ) {
        super(message);
        this.name = 'ApiError';
    }
}

// Types
export interface User {
    id: number;
    name: string;
    username: string;
    email: string;
    bio?: string;
    location?: string;
    birthday?: string;
    website?: string;
    profile_image_url?: string;
    cover_image_url?: string;
    profileImageURL?: string;
    coverImageURL?: string;
    is_admin: boolean;
    isAdmin?: boolean;
    has_completed_setup: boolean;
    posts_count?: number;
    comments_count?: number;
    likes_count?: number;
    bookmarks_count?: number;
    followers_count?: number;
    following_count?: number;
    created_at: string;
    updated_at: string;
}

export interface Post {
    id: number;
    user_id: number;
    content: string;
    user?: Pick<User, 'id' | 'name' | 'username' | 'profile_image_url'>;
    images?: { id: number; image_url: string }[];
    comments_count?: number;
    likes_count?: number;
    bookmarks_count?: number;
    created_at: string;
    updated_at: string;
}

export interface PortalSlide {
    id: number;
    image_url: string;
    imageURL?: string;
    title?: string;
    link_url?: string;
    sort_order: number;
    is_active: boolean;
    created_at?: string;
    updated_at?: string;
}

export interface Announcement {
    id: number;
    title: string;
    content: string;
    published_at: string | null;
    is_active: boolean;
    priority: number;
    created_at: string;
    updated_at: string;
}

export interface UserStats {
    total_users: number;
    admin_users: number;
    new_users_today: number;
    new_users_this_week: number;
    new_users_this_month: number;
}

export interface PostStats {
    total_posts: number;
    new_posts_today: number;
    new_posts_this_week: number;
    new_posts_this_month: number;
}


export interface PaginatedResponse<T> {
    data: T[];
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
}

export interface UserQueryParams {
    page?: string;
    per_page?: string;
    search?: string;
    is_admin?: string;
    sort_by?: string;
    sort_order?: string;
}

export interface PostQueryParams {
    page?: string;
    per_page?: string;
    search?: string;
    user_id?: string;
    sort_by?: string;
    sort_order?: string;
}

export const api = new ApiClient(API_BASE_URL);
